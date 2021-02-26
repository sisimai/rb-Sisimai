module Sisimai::Lhost
  # Sisimai::Lhost::Yahoo parses a bounce email which created by Yahoo! MAIL. Methods in the module
  # are called from only Sisimai::Message.
  module Yahoo
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^--- Below this line is a copy of the message[.]|.freeze
      StartingOf = { message: ['Sorry, we were unable to deliver your message'] }.freeze

      # Parse bounce messages from Yahoo! MAIL
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # X-YMailISG: YtyUVyYWLDsbDh...
        # X-YMail-JAS: Pb65aU4VM1mei...
        # X-YMail-OSG: bTIbpDEVM1lHz...
        # X-Originating-IP: [192.0.2.9]
        return nil unless mhead['x-ymailisg']

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # Sorry, we were unable to deliver your message to the following address.
          #
          # <kijitora@example.org>:
          # Remote host said: 550 5.1.1 <kijitora@example.org>... User Unknown [RCPT_TO]
          v = dscontents[-1]

          if cv = e.match(/\A[<](.+[@].+)[>]:[ \t]*\z/)
            # <kijitora@example.org>:
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            v['diagnosis'] = ''
            recipients += 1
          else
            if e.start_with?('Remote host said:')
              # Remote host said: 550 5.1.1 <kijitora@example.org>... User Unknown [RCPT_TO]
              v['diagnosis'] = e

              # Get SMTP command from the value of "Remote host said:"
              if cv = e.match(/\[([A-Z]{4}).*\]\z/) then v['command'] = cv[1] end
            else
              # <mailboxfull@example.jp>:
              # Remote host said:
              # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
              # [RCPT_TO]
              if v['diagnosis'].start_with?('Remote host said:')
                # Remote host said:
                # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                if cv = e.match(/\[([A-Z]{4}).*\]\z/)
                  # [RCPT_TO]
                  v['command'] = cv[1]
                else
                  # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                  v['diagnosis'] = e
                end
              else
                # Error message which does not start with 'Remote host said:'
                v['diagnosis'] << ' ' << e
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].gsub(/\\n/, ' '))
          e['command'] ||= 'RCPT' if e['diagnosis'] =~ /[<].+[@].+[>]/
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Yahoo! MAIL: https://www.yahoo.com'; end
    end
  end
end

