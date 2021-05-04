module Sisimai
  # Sisimai::RFC3464 - bounce mail parser class for Fallback.
  module RFC3464
    class << self
      require 'sisimai/lhost'

      # http://tools.ietf.org/html/rfc3464
      Indicators = Sisimai::Lhost.INDICATORS
      MarkingsOf = {
        message: %r{\A(?>
           content-type:[ ]*(?:
             message/x?delivery-status
            |message/disposition-notification
            |text/plain;[ ]charset=
            )
          |the[ ]original[ ]message[ ]was[ ]received[ ]at[ ]
          |this[ ]report[ ]relates[ ]to[ ]your[ ]message
          |your[ ]message[ ](?:
             could[ ]not[ ]be[ ]delivered
            |was[ ]not[ ]delivered[ ]to[ ]the[ ]following[ ]recipients
            )
          )
        }x,
        rfc822:  %r{\A(?>
           content-type:[ ]*(?:message/rfc822|text/rfc822-headers)
          |return-path:[ ]*[<].+[>]
          )\z
        }x,
        error:   %r/\A(?:[45]\d\d[ \t]+|[<][^@]+[@][^@]+[>]:?[ \t]+)/,
        command: %r/[ ](RCPT|MAIL|DATA)[ ]+command\b/,
      }.freeze
      ReSkip = %r{(?>
         \A[-]+=
        |\A\s+\z
        |\A\s*--
        |\A\s+[=]\d+
        |\Ahi[ ][!]
        |content-(?:description|disposition|transfer-encoding|type):[ ]
        |(?:name|charset)=
        |--\z
        |:[ ]--------
        )
      }x.freeze
      ReStop = %r{(?:
         \A[*][*][*][ ].+[ ].+[ ][*][*][*]
        |\Acontent-type:[ ]message/delivery-status
        |\Ahere[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]first[ ]part[ ]of[ ]the[ ]message
        |\Athe[ ]non-delivered[ ]message[ ]is[ ]attached[ ]to[ ]this[ ]message.
        |\Areceived:[ \t]*
        |\Areceived-from-mta:[ \t]*
        |\Areporting-mta:[ \t]*
        |\Areturn-path:[ \t]*
        |\Aa[ ]copy[ ]of[ ]the[ ]original[ ]message[ ]below[ ]this[ ]line:
        |attachment[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]message
        |below[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]original[ ]message:
        |below[ ]this[ ]line[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]message
        |message[ ]contains[ ].+[ ]file[ ]attachments
        |message[ ]text[ ]follows:[ ]
        |original[ ]message[ ]follows
        |the[ ]attachment[ ]contains[ ]the[ ]original[ ]mail[ ]headers
        |the[ ]first[ ]\d+[ ]lines[ ]
        |unsent[ ]Message[ ]below
        |your[ ]message[ ]reads[ ][(]in[ ]part[)]:
        )
      }x.freeze
      ReAddr = %r{(?:
         \A\s*
        |\A["].+["]\s*
        |\A[ \t]*Recipient:[ \t]*
        |\A[ ]*Address:[ ]
        |addressed[ ]to[ ]
        |Could[ ]not[ ]be[ ]delivered[ ]to:[ ]
        |delivered[ ]to[ ]+
        |delivery[ ]failed:[ ]
        |Did[ ]not[ ]reach[ ]the[ ]following[ ]recipient:[ ]
        |Error-for:[ ]+
        |Failed[ ]Recipient:[ ]
        |Failed[ ]to[ ]deliver[ ]to[ ]
        |Intended[ ]recipient:[ ]
        |Mailbox[ ]is[ ]full:[ ]
        |RCPT[ ]To:
        |SMTP[ ]Server[ ][<].+[>][ ]rejected[ ]recipient[ ]
        |The[ ]following[ ]recipients[ ]returned[ ]permanent[ ]errors:[ ]
        |The[ ]following[ ]message[ ]to[ ]
        |Unknown[ ]User:[ ]
        |undeliverable[ ]to[ ]
        |Undeliverable[ ]Address:[ ]*
        |You[ ]sent[ ]mail[ ]to[ ]
        |Your[ ]message[ ]to[ ]
        )
        ['"]?[<]?([^\s\n\r@=<>]+[@][-.0-9A-Za-z]+[.][0-9A-Za-z]+)[>]?['"]?
      }xi.freeze

      # Detect an error for RFC3464
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        bodyslices = mbody.scrub('?').split("\n")
        readslices = ['']
        rfc822text = ''   # (String) message/rfc822 part text
        maybealias = nil  # (String) Original-Recipient Field
        blanklines = 0    # (Integer) The number of blank lines
        readcursor = 0    # (Integer) Points the current cursor position
        recipients = 0    # (Integer) The number of 'Final-Recipient' header
        itisbounce = false
        connheader = {
          'date'  => nil, # The value of Arrival-Date header
          'rhost' => nil, # The value of Reporting-MTA header
          'lhost' => nil, # The value of Received-From-MTA header
        }
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop
          d = e.downcase

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if d =~ MarkingsOf[:message]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if d =~ MarkingsOf[:rfc822]
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # Inside of the original message part
            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822text << e << "\n"
          else
            # Error message part
            next unless readcursor & Indicators[:deliverystatus] > 0
            next if e.empty?

            v = dscontents[-1]
            if cv = e.match(/\A(Final|Original)-[Rr]ecipient:[ ]*.+;[ ]*([^ ]+)\z/)
              # 2.3.2 Final-Recipient field
              #   The Final-Recipient field indicates the recipient for which this set
              #   of per-recipient fields applies.  This field MUST be present in each
              #   set of per-recipient data.
              #   The syntax of the field is as follows:
              #
              #       final-recipient-field =
              #           "Final-Recipient" ":" address-type ";" generic-address
              #
              # 2.3.1 Original-Recipient field
              #   The Original-Recipient field indicates the original recipient address
              #   as specified by the sender of the message for which the DSN is being
              #   issued.
              #
              #       original-recipient-field =
              #           "Original-Recipient" ":" address-type ";" generic-address
              #
              #       generic-address = *text
              if cv[1] == 'Original'
                # Original-Recipient: ...
                maybealias = cv[2]
              else
                # Final-Recipient: ...
                x = v['recipient'] || ''
                y = Sisimai::Address.s3s4(cv[2])
                y = maybealias unless Sisimai::Address.is_emailaddress(y)

                if !x.empty? && x != y
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Lhost.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = y
                recipients += 1
                itisbounce ||= true

                v['alias'] ||= maybealias
                maybealias = nil
              end

            elsif cv = e.match(/\AX-Actual-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
              # X-Actual-Recipient: RFC822; |IFS=' ' && exec procmail -f- || exit 75 ...
              # X-Actual-Recipient: rfc822; kijitora@neko.example.jp
              v['alias'] = cv[1] unless cv[1] =~ /[ \t]+/

            elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
              # 2.3.3 Action field
              #   The Action field indicates the action performed by the Reporting-MTA
              #   as a result of its attempt to deliver the message to this recipient
              #   address.  This field MUST be present for each recipient named in the
              #   DSN.
              #   The syntax for the action-field is:
              #
              #       action-field = "Action" ":" action-value
              #       action-value =
              #           "failed" / "delayed" / "delivered" / "relayed" / "expanded"
              #
              #   The action-value may be spelled in any combination of upper and lower
              #   case characters.
              v['action'] = cv[1].downcase

              # failed (bad destination mailbox address)
              if cv = v['action'].match(/\A([^ ]+)[ ]/) then v['action'] = cv[1] end

            elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
              # 2.3.4 Status field
              #   The per-recipient Status field contains a transport-independent
              #   status code that indicates the delivery status of the message to that
              #   recipient.  This field MUST be present for each delivery attempt
              #   which is described by a DSN.
              #
              #   The syntax of the status field is:
              #
              #       status-field = "Status" ":" status-code
              #       status-code = DIGIT "." 1*3DIGIT "." 1*3DIGIT
              v['status'] = cv[1]

            elsif cv = e.match(/\AStatus:[ ]*(\d+[ ]+.+)\z/)
              # Status: 553 Exceeded maximum inbound message size
              v['alterrors'] = cv[1]

            elsif cv = e.match(/\ARemote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
              # 2.3.5 Remote-MTA field
              #   The value associated with the Remote-MTA DSN field is a printable
              #   ASCII representation of the name of the "remote" MTA that reported
              #   delivery status to the "reporting" MTA.
              #
              #       remote-mta-field = "Remote-MTA" ":" mta-name-type ";" mta-name
              #
              #   NOTE: The Remote-MTA field preserves the "while talking to"
              #   information that was provided in some pre-existing nondelivery
              #   reports.
              #
              #   This field is optional.  It MUST NOT be included if no remote MTA was
              #   involved in the attempted delivery of the message to that recipient.
              v['rhost'] = cv[1].downcase

            elsif cv = e.match(/\ALast-Attempt-Date:[ ]*(.+)\z/)
              # 2.3.7 Last-Attempt-Date field
              #   The Last-Attempt-Date field gives the date and time of the last
              #   attempt to relay, gateway, or deliver the message (whether successful
              #   or unsuccessful) by the Reporting MTA.  This is not necessarily the
              #   same as the value of the Date field from the header of the message
              #   used to transmit this delivery status notification: In cases where
              #   the DSN was generated by a gateway, the Date field in the message
              #   header contains the time the DSN was sent by the gateway and the DSN
              #   Last-Attempt-Date field contains the time the last delivery attempt
              #   occurred.
              #
              #       last-attempt-date-field = "Last-Attempt-Date" ":" date-time
              v['date'] = cv[1]
            else
              if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                # 2.3.6 Diagnostic-Code field
                #   For a "failed" or "delayed" recipient, the Diagnostic-Code DSN field
                #   contains the actual diagnostic code issued by the mail transport.
                #   Since such codes vary from one mail transport to another, the
                #   diagnostic-type sub-field is needed to specify which type of
                #   diagnostic code is represented.
                #
                #       diagnostic-code-field =
                #           "Diagnostic-Code" ":" diagnostic-type ";" *text
                v['spec'] = cv[1].upcase
                v['diagnosis'] = cv[2]

              elsif cv = e.match(/\ADiagnostic-Code:[ ]*(.+)\z/)
                # No value of "diagnostic-type"
                # Diagnostic-Code: 554 ...
                v['diagnosis'] = cv[1]

              elsif readslices[-2].start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                # Continued line of the value of Diagnostic-Code header
                v['diagnosis'] << ' ' << cv[1]
                readslices[-1] = 'Diagnostic-Code: ' << e
              else
                if cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # 2.2.2 The Reporting-MTA DSN field
                  #
                  #       reporting-mta-field =
                  #           "Reporting-MTA" ":" mta-name-type ";" mta-name
                  #       mta-name = *text
                  #
                  #   The Reporting-MTA field is defined as follows:
                  #
                  #   A DSN describes the results of attempts to deliver, relay, or gateway
                  #   a message to one or more recipients.  In all cases, the Reporting-MTA
                  #   is the MTA that attempted to perform the delivery, relay, or gateway
                  #   operation described in the DSN.  This field is required.
                  connheader['rhost'] ||= cv[1].downcase

                elsif cv = e.match(/\AReceived-From-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # 2.2.4 The Received-From-MTA DSN field
                  #   The optional Received-From-MTA field indicates the name of the MTA
                  #   from which the message was received.
                  #
                  #       received-from-mta-field =
                  #           "Received-From-MTA" ":" mta-name-type ";" mta-name
                  #
                  #   If the message was received from an Internet host via SMTP, the
                  #   contents of the mta-name sub-field SHOULD be the Internet domain name
                  #   supplied in the HELO or EHLO command, and the network address used by
                  #   the SMTP client SHOULD be included as a comment enclosed in
                  #   parentheses.  (In this case, the MTA-name-type will be "dns".)
                  connheader['lhost'] = cv[1].downcase

                elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
                  # 2.2.5 The Arrival-Date DSN field
                  #   The optional Arrival-Date field indicates the date and time at which
                  #   the message arrived at the Reporting MTA.  If the Last-Attempt-Date
                  #   field is also provided in a per-recipient field, this can be used to
                  #   determine the interval between when the message arrived at the
                  #   Reporting MTA and when the report was issued for that recipient.
                  #
                  #       arrival-date-field = "Arrival-Date" ":" date-time
                  connheader['date'] = cv[1]
                else
                  # Get error message
                  next if e.start_with?(' ', '-')
                  next unless e =~ MarkingsOf[:error]

                  # 500 User Unknown
                  # <kijitora@example.jp> Unknown
                  v['alterrors'] ||= ' '
                  v['alterrors']  << ' ' << e
                end
              end
            end
          end # End of if: rfc822
        end

        while true
          # Fallback, parse entire message body
          break if recipients > 0
          match = 0
          mfrom = mhead['from'].downcase

          # Failed to get a recipient address at code above
          match += 1 if mfrom.include?('postmaster@') || mfrom.include?('mailer-daemon@') || mfrom.include?('root@')
          match += 1 if mhead['subject'].downcase =~ %r{(?>
             delivery[ ](?:failed|failure|report)
            |failure[ ]notice
            |mail[ ](?:delivery|error)
            |non[-]delivery
            |returned[ ]mail
            |undeliverable[ ]mail
            |warning:[ ]
            )
          }x

          if mhead['return-path']
            # Check the value of Return-Path of the message
            rpath  = mhead['return-path'].downcase
            match += 1 if rpath.include?('<>') || rpath.include?('mailer-daemon')
          end
          break unless match > 0

          b = dscontents[-1]
          bodyslices = mbody.split("\n")
          while e = bodyslices.shift do
            # Get the recipient's email address and error messages.
            d = e.downcase
            break if d =~ MarkingsOf[:rfc822]
            break if d =~ ReStop

            next if e.empty?
            next if d =~ ReSkip
            next if e.start_with?('*')

            if cv = e.match(ReAddr)
              # May be an email address
              x = b['recipient'] || ''
              y = Sisimai::Address.s3s4(cv[1])
              next unless Sisimai::Address.is_emailaddress(y)

              if !x.empty? && x != y
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                b = dscontents[-1]
              end
              b['recipient'] = y
              recipients += 1
              itisbounce ||= true

            elsif cv = e.match(/[(](?:expanded|generated)[ ]from:?[ ]([^@]+[@][^@]+)[)]/)
              # (expanded from: neko@example.jp)
              b['alias'] = Sisimai::Address.s3s4(cv[1])
            end
            b['diagnosis'] ||= ''
            b['diagnosis']  << ' ' << e
          end

          break
        end
        return nil unless itisbounce

        if recipients == 0 && cv = rfc822text.match(/^To:[ ]*(.+)/)
          # Try to get a recipient address from "To:" header of the original message
          if r = Sisimai::Address.find(cv[1], true)
            # Found a recipient address
            dscontents << Sisimai::Lhost.DELIVERYSTATUS if dscontents.size == recipients
            b = dscontents[-1]
            b['recipient'] = r[0][:address]
            recipients += 1
          end
        end
        return nil unless recipients > 0

        require 'sisimai/mda'
        mdabounced = Sisimai::MDA.inquire(mhead, mbody)
        dscontents.each do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }

          if e['alterrors']
            # Copy alternative error message
            unless e['alterrors'].empty?
              e['diagnosis'] ||= e['alterrors']
              if e['diagnosis'].start_with?('-') || e['diagnosis'].end_with?('__')
                # Override the value of diagnostic code message
                e['diagnosis'] = e['alterrors']
              end
              e.delete('alterrors')
            end
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

          if mdabounced
            # Make bounce data by the values returned from Sisimai::MDA.inquire()
            e['agent']     = mdabounced['mda'] || 'RFC3464'
            e['reason']    = mdabounced['reason'] || 'undefined'
            e['diagnosis'] = mdabounced['message'] unless mdabounced['message'].empty?
            e['command']   = ''
          end

          e['status'] ||= Sisimai::SMTP::Status.find(e['diagnosis']) || ''
          if cv = e['diagnosis'].match(MarkingsOf[:command])
            e['command'] = cv[1]
          end
          e['date'] ||= mhead['date']
        end

        return { 'ds' => dscontents, 'rfc822' => rfc822text }
      end
      def description; 'Fallback Module for MTAs'; end
    end
  end
end
