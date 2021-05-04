module Sisimai::Lhost
  # Sisimai::Lhost::Sendmail parses a bounce email which created by v8 Sendmail. Methods in the module
  # are called from only Sisimai::Message.
  module Sendmail
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r<^Content-Type:[ ](?:message/rfc822|text/rfc822-headers)>.freeze
      StartingOf = {
        # Error text regular expressions which defined in sendmail/savemail.c
        #   savemail.c:1040|if (printheader && !putline("   ----- Transcript of session follows -----\n",
        #   savemail.c:1041|          mci))
        #   savemail.c:1042|  goto writeerr;
        #   savemail.c:1360|if (!putline(
        #   savemail.c:1361|    sendbody
        #   savemail.c:1362|    ? "   ----- Original message follows -----\n"
        #   savemail.c:1363|    : "   ----- Message header follows -----\n",
        message: ['   ----- Transcript of session follows -----'],
        error:   ['... while talking to '],
      }.freeze

      # Parse bounce messages from Sendmail
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'] =~ /(?:see transcript for details\z|\AWarning: )/
        return nil if mhead['x-aol-ip']

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readslices = ['']
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
        esmtpreply = []     # (Array) Reply from remote server on SMTP session
        sessionerr = false  # (Boolean) Flag, "true" if it is SMTP session error
        anotherset = {}     # Another error information
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          if f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            o = Sisimai::RFC1894.field(e) || next
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
              v['diagnosis'] = o[2]
            else
              # Other DSN fields defined in RFC3464
              next unless fieldtable[o[0]]
              v[fieldtable[o[0]]] = o[2]

              next unless f == 1
              permessage[fieldtable[o[0]]] = o[2]
            end
          else
            # The line does not begin with a DSN field defined in RFC3464
            #
            # ----- Transcript of session follows -----
            # ... while talking to mta.example.org.:
            # >>> DATA
            # <<< 550 Unknown user recipient@example.jp
            # 554 5.0.0 Service unavailable
            # ...
            # Reporting-MTA: dns; mx.example.jp
            # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
            # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
            unless e.start_with?(' ')
              if cv = e.match(/\A[>]{3}[ ]+([A-Z]{4})[ ]?/)
                # >>> DATA
                commandtxt = cv[1]

              elsif cv = e.match(/\A[<]{3}[ ]+(.+)\z/)
                # <<< Response
                esmtpreply << cv[1] unless esmtpreply.index(cv[1])
              else
                # Detect SMTP session error or connection error
                next if sessionerr
                if e.start_with?(StartingOf[:error][0])
                  # ----- Transcript of session follows -----
                  # ... while talking to mta.example.org.:
                  sessionerr = true
                  next
                end

                if cv = e.match(/\A[<](.+)[>][.]+ (.+)\z/)
                  # <kijitora@example.co.jp>... Deferred: Name server: example.co.jp.: host name lookup failure
                  anotherset['recipient'] = cv[1]
                  anotherset['diagnosis'] = cv[2]
                else
                  # ----- Transcript of session follows -----
                  # Message could not be delivered for too long
                  # Message will be deleted from queue
                  next if e =~ /\A[ \t]*[-]+/
                  if cv = e.match(/\A[45]\d\d[ \t]([45][.]\d[.]\d)[ \t].+/)
                    # 550 5.1.2 <kijitora@example.org>... Message
                    #
                    # DBI connect('dbname=...')
                    # 554 5.3.0 unknown mailer error 255
                    anotherset['status'] = cv[1]
                    anotherset['diagnosis'] ||= ''
                    anotherset['diagnosis'] << ' ' << e

                  elsif e.start_with?('Message ', 'Warning: ')
                    # Message could not be delivered for too long
                    # Warning: message still undelivered after 4 hours
                    anotherset['diagnosis'] ||= ''
                    anotherset['diagnosis'] << ' ' << e
                  end
                end
              end
            else
              # Continued line of the value of Diagnostic-Code field
              next unless readslices[-2].start_with?('Diagnostic-Code:')
              next unless cv = e.match(/\A[ \t]+(.+)\z/)
              v['diagnosis'] << ' ' << cv[1]
              readslices[-1] = 'Diagnostic-Code: ' << e
            end
          end
        end # End of message/delivery-status
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          e['lhost'] ||= permessage['rhost']
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }

          e['command'] ||= commandtxt
          if e['command'].empty?
            e['command'] = 'EHLO' unless esmtpreply.empty?
          end

          if anotherset['diagnosis']
            # Copy alternative error message
            e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'] =~ /\A[ \t]+\z/
            e['diagnosis'] = anotherset['diagnosis'] unless e['diagnosis']
            e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'] =~ /\A\d+\z/
          end
          unless esmtpreply.empty?
            # Replace the error message in "diagnosis" with the ESMTP Reply
            r = esmtpreply.join(' ')
            e['diagnosis'] = r if r.size > e['diagnosis'].to_s.size
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          if anotherset['status']
            # Check alternative status code
            if e['status'].empty? || e['status'] !~ /\A[45][.]\d[.]\d{1,3}\z/
              # Override alternative status code
              e['status'] = anotherset['status']
            end
          end

          unless e['recipient'] =~ /\A[^ ]+[@][^ ]+\z/
            # @example.jp, no local part
            if cv = e['diagnosis'].match(/[<]([^ ]+[@][^ ]+)[>]/)
              # Get email address from the value of Diagnostic-Code header
              e['recipient'] = cv[1]
            end
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'V8Sendmail: /usr/sbin/sendmail'; end
    end
  end
end
