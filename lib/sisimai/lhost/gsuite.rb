module Sisimai::Lhost
  # Sisimai::Lhost::GSuite parses a bounce email which created by G Suite. Methods in the module are
  # called from only Sisimai::Message.
  module GSuite
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r<^Content-Type:[ ](?:message/rfc822|text/rfc822-headers)>.freeze
      MarkingsOf = {
        message: %r/\A[*][*][ ].+[ ][*][*]\z/,
        error:   %r/\AThe[ ]response([ ]from[ ]the[ ]remote[ ]server)?[ ]was:\z/,
        html:    %r{\AContent-Type:[ ]*text/html;[ ]*charset=['"]?(?:UTF|utf)[-]8['"]?\z},
      }.freeze
      MessagesOf = {
        'userunknown'  => ["because the address couldn't be found. Check for typos or unnecessary spaces and try again."],
        'notaccept'    => ['Null MX'],
        'networkerror' => [' had no relevant answers.', ' responded with code NXDOMAIN'],
      }.freeze

      # Parse bounce messages from G Suite (Transfer from G Suite to a destinaion host)
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['from'].end_with?('<mailer-daemon@googlemail.com>')
        return nil unless mhead['subject'].start_with?('Delivery Status Notification')
        return nil unless mhead['x-gm-message-state']

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        endoferror = false  # (Integer) Flag for a blank line after error messages
        anotherset = {}     # (Hash) Another error information
        emptylines = 0      # (Integer) The number of empty lines
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e =~ MarkingsOf[:message]
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0

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
              v['diagnosis'] = o[2]
            else
              # Other DSN fields defined in RFC3464
              next unless fieldtable[o[0]]
              v[fieldtable[o[0]]] = o[2]

              if fieldtable[o[0]] == 'lhost'
                # Do not set an email address as a hostname in "lhost" value
                v['lhost'] = '' if v['lhost'].include?('@')
              end

              next unless f == 1
              permessage[fieldtable[o[0]]] = o[2]
            end
          else
            # The line does not begin with a DSN field defined in RFC3464 Append error messages continued
            # from the previous line
            if endoferror == false && v && ! v['diagnosis'].to_s.empty?
              endoferror ||= true if e.empty?

              next if endoferror
              next unless e.start_with?(' ')
              v['diagnosis'] << e

            elsif e =~ MarkingsOf[:error]
              # Detect SMTP session error or connection error
              # The response from the remote server was:
              anotherset['diagnosis'] << e
            else
              # ** Address not found **
              #
              # Your message wasn't delivered to * because the address couldn't be found.
              # Check for typos or unnecessary spaces and try again.
              #
              # The response from the remote server was:
              # 550 #5.1.0 Address rejected.
              next if e =~ MarkingsOf[:html]

              if anotherset['diagnosis']
                # Continued error messages from the previous line like "550 #5.1.0 Address rejected."
                next if e =~ /\AContent-Type:/
                next if emptylines > 5
                if e.empty?
                  # Count and next()
                  emptylines += 1
                  next
                end
                anotherset['diagnosis'] << ' ' << e
              else
                # ** Address not found **
                #
                # Your message wasn't delivered to * because the address couldn't be found.
                # Check for typos or unnecessary spaces and try again.
                next if e.empty?
                next unless e =~ MarkingsOf[:message]
                anotherset['diagnosis'] = e
              end
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

              if e['replycode'].empty? || e['replycode'].start_with?('400', '500')
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
          MessagesOf.each_key do |r|
            # Guess an reason of the bounce
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'G Suite: https://gsuite.google.com'; end
    end
  end
end

