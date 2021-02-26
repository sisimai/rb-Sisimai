module Sisimai::Lhost
  # Sisimai::Lhost::Postfix parses a bounce email which created by Postfix. Methods in the module are
  # called from only Sisimai::Message.
  module Postfix
    class << self
      require 'sisimai/lhost'

      # Postfix manual - bounce(5) - http://www.postfix.org/bounce.5.html
      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r<^Content-Type:[ ](?:message/rfc822|text/rfc822-headers)>.freeze
      MarkingsOf = {
        message: %r{\A(?>
           [ ]+The[ ](?:
             Postfix[ ](?:
               program\z              # The Postfix program
              |on[ ].+[ ]program\z    # The Postfix on <os name> program
              )
            |\w+[ ]Postfix[ ]program\z  # The <name> Postfix program
            |mail[ \t]system\z             # The mail system
            |\w+[ \t]program\z             # The <custmized-name> program
            )
          |This[ ]is[ ]the[ ](?:
             Postfix[ ]program          # This is the Postfix program
            |\w+[ ]Postfix[ ]program    # This is the <name> Postfix program
            |\w+[ ]program              # This is the <customized-name> Postfix program
            |mail[ ]system[ ]at[ ]host  # This is the mail system at host <hostname>.
            )
          )
        }x,
        # :from => %r/ [(]Mail Delivery System[)]\z/,
      }.freeze

      # Parse bounce messages from Postfix
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'] == 'Undelivered Mail Returned to Sender'
        return nil if mhead['x-aol-ip']

        require 'sisimai/rfc1894'
        require 'sisimai/address'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readslices = ['']
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        nomessages = false  # (Boolean) Delivery report unavailable
        commandset = []     # (Array) ``in reply to * command'' list
        anotherset = {}     # Another error information
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e =~ MarkingsOf[:message]
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          if f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            next unless o = Sisimai::RFC1894.field(e)
            v = dscontents[-1]

            if o[-1] == 'addr'
              # Final-Recipient: rfc822; kijitora@example.jp
              # X-Actual-Recipient: rfc822; kijitora@example.co.jp
              if o[0] == 'final-recipient'
                # Final-Recipient: rfc822; kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Lhost.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = o[2]
                recipients += 1
              else
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                v['alias'] = o[2]
              end
            elsif o[-1] == 'code'
              # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
              v['spec'] = o[1]
              v['spec'] = 'SMTP' if v['spec'] == 'X-POSTFIX'
              v['diagnosis'] = o[2]
            else
              # Other DSN fields defined in RFC3464
              next unless fieldtable[o[0]]
              v[fieldtable[o[0]]] = o[2]

              next unless f == 1
              permessage[fieldtable[o[0]]] = o[2]
            end
          else
            # If you do so, please include this problem report. You can
            # delete your own text from the attached returned message.
            #
            #           The mail system
            #
            # <userunknown@example.co.jp>: host mx.example.co.jp[192.0.2.153] said: 550
            # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO command)
            if readslices[-2].start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
              # Continued line of the value of Diagnostic-Code header
              v['diagnosis'] << ' ' << cv[1]
              readslices[-1] = 'Diagnostic-Code: ' << e

            elsif cv = e.match(/\A(X-Postfix-Sender):[ ]*rfc822;[ ]*(.+)\z/)
              # X-Postfix-Sender: rfc822; shironeko@example.org
              emailsteak[1] << cv[1] << ': ' << cv[2] << "\n"

            else
              if cv = e.match(/[ \t][(]in reply to (?:end of )?([A-Z]{4}).*/) ||
                 cv = e.match(/([A-Z]{4})[ \t]*.*command[)]\z/)
                # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO
                commandset << cv[1]
                anotherset['diagnosis'] ||= ''
                anotherset['diagnosis'] << ' ' << e
              else
                # Alternative error message and recipient
                if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>] [(]expanded from [<](.+)[>][)]:[ \t]*(.+)\z/)
                  # <r@example.ne.jp> (expanded from <kijitora@example.org>): user ...
                  anotherset['recipient'] = cv[1]
                  anotherset['alias']     = cv[2]
                  anotherset['diagnosis'] = cv[3]

                elsif cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>]:(.*)\z/)
                  # <kijitora@exmaple.jp>: ...
                  anotherset['recipient'] = cv[1]
                  anotherset['diagnosis'] = cv[2]

                elsif e.include?('--- Delivery report unavailable ---')
                  # postfix-3.1.4/src/bounce/bounce_notify_util.c
                  # bounce_notify_util.c:602|if (bounce_info->log_handle == 0
                  # bounce_notify_util.c:602||| bounce_log_rewind(bounce_info->log_handle)) {
                  # bounce_notify_util.c:602|if (IS_FAILURE_TEMPLATE(bounce_info->template)) {
                  # bounce_notify_util.c:602|    post_mail_fputs(bounce, "");
                  # bounce_notify_util.c:602|    post_mail_fputs(bounce, "\t--- delivery report unavailable ---");
                  # bounce_notify_util.c:602|    count = 1;              /* xxx don't abort */
                  # bounce_notify_util.c:602|}
                  # bounce_notify_util.c:602|} else {
                  nomessages = true
                else
                  # Get error message continued from the previous line
                  next unless anotherset['diagnosis']
                  if e =~ /\A[ \t]{4}(.+)\z/
                    #    host mx.example.jp said:...
                    anotherset['diagnosis'] << ' ' << e
                  end
                end
              end
            end
          end
        end

        unless recipients > 0
          # Fallback: get a recipient address from error messages
          if anotherset['recipient'].to_s.size > 0
            # Set a recipient address
            dscontents[-1]['recipient'] = anotherset['recipient']
            recipients += 1
          else
            # Get a recipient address from message/rfc822 part if the delivery report was unavailable:
            # '--- Delivery report unavailable ---'
            if nomessages && cv = emailsteak[1].match(/^To:[ ]*(.+)$/)
              # Try to get a recipient address from To: field in the original message at message/rfc822 part
              dscontents[-1]['recipient'] = Sisimai::Address.s3s4(cv[1])
              recipients += 1
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          e['lhost'] ||= permessage['rhost']
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }

          if anotherset['diagnosis']
            # Copy alternative error message
            e['diagnosis'] = anotherset['diagnosis'] unless e['diagnosis']

            if e['diagnosis'] =~ /\A\d+\z/
              e['diagnosis'] = anotherset['diagnosis']
            else
              # More detailed error message is in "anotherset"
              as = nil  # status
              ar = nil  # replycode

              e['status']    ||= ''
              e['replycode'] ||= ''

              if e['status'] == '' || e['status'].start_with?('4.0.0', '5.0.0')
                # Check the value of D.S.N. in anotherset
                as = Sisimai::SMTP::Status.find(anotherset['diagnosis'])
                if as && as[-3, 3] != '0.0'
                  # The D.S.N. is neither an empty nor *.0.0
                  e['status'] = as
                end
              end

              if e['replycode'] == '' || e['replycode'].start_with?('400', '500')
                # Check the value of SMTP reply code in anotherset
                ar = Sisimai::SMTP::Reply.find(anotherset['diagnosis'])
                if ar && ar[-2, 2].to_i != 0
                  # The SMTP reply code is neither an empty nor *00
                  e['replycode'] = ar
                end
              end

              if (as || ar) && (anotherset['diagnosis'].size > e['diagnosis'].size)
                # Update the error message in e['diagnosis']
                e['diagnosis'] = anotherset['diagnosis']
              end
            end
          end

          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['command']   = commandset.shift || nil
          e['command'] ||= 'HELO' if e['diagnosis'] =~ /refused to talk to me:/
          e['spec']    ||= 'SMTP' if e['diagnosis'] =~ /host .+ said:/
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Postfix'; end
    end
  end
end

