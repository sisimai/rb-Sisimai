module Sisimai::Lhost
  # Sisimai::Lhost::SendGrid parses a bounce email which created by SendGrid. Methods in the module
  # are called from only Sisimai::Message.
  module SendGrid
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = { message: ['This is an automatically generated message from SendGrid.'] }.freeze

      # Parse bounce messages from SendGrid
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # Return-Path: <apps@sendgrid.net>
        # X-Mailer: MIME-tools 5.502 (Entity 5.502)
        return nil unless mhead['return-path']
        return nil unless mhead['return-path'] == '<apps@sendgrid.net>'
        return nil unless mhead['subject'] == 'Undelivered Mail Returned to Sender'

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
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e == StartingOf[:message][0]
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          if f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            o = Sisimai::RFC1894.field(e)
            v = dscontents[-1]

            unless o
              # Fallback code for empty value or invalid formatted value
              # - Status: (empty)
              # - Diagnostic-Code: 550 5.1.1 ... (No "diagnostic-type" sub field)
              next unless cv = e.match(/\ADiagnostic-Code:[ ]*(.+)/)
              v['diagnosis'] = cv[1]
              next
            end

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
            elsif o[-1] == 'date'
              # Arrival-Date: 2012-12-31 23-59-59
              next unless cv = e.match(/\AArrival-Date: (\d{4})[-](\d{2})[-](\d{2}) (\d{2})[-](\d{2})[-](\d{2})\z/)
              o[1] << 'Thu, ' << cv[3] + ' '
              o[1] << Sisimai::DateTime.monthname(false)[cv[2].to_i - 1]
              o[1] << ' ' << cv[1] + ' ' << [cv[4], cv[5], cv[6]].join(':')
              o[1] << ' ' << Sisimai::DateTime.abbr2tz('CDT')
            else
              # Other DSN fields defined in RFC3464
              next unless fieldtable[o[0]]
              v[fieldtable[o[0]]] = o[2]

              next unless f == 1
              permessage[fieldtable[o[0]]] = o[2]
            end
          else
            # The line does not begin with a DSN field defined in RFC3464
            if cv = e.match(/.+ in (?:End of )?([A-Z]{4}).*\z/)
              # in RCPT TO, in MAIL FROM, end of DATA
              commandtxt = cv[1]
            else
              # Continued line of the value of Diagnostic-Code field
              next unless readslices[-2].start_with?('Diagnostic-Code:')
              next unless cv = e.match(/\A[ \t]+(.+)\z/)
              v['diagnosis'] << ' ' << cv[1]
              readslices[-1] = 'Diagnostic-Code: ' << e
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Get the value of SMTP status code as a pseudo D.S.N.
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          if cv = e['diagnosis'].match(/\b([45])\d\d[ \t]*/)
            # 4xx or 5xx
            e['status'] = cv[1] + '.0.0'
          end

          if e['status'] == '5.0.0' || e['status'] == '4.0.0'
            # Get the value of D.S.N. from the error message or the value of Diagnostic-Code header.
            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis']) || e['status']
          end

          if e['action'] == 'expired'
            # Action: expired
            e['reason'] = 'expired'
            if !e['status'] || e['status'].end_with?('.0.0')
              # Set pseudo Status code value if the value of Status is not defined or 4.0.0 or 5.0.0.
              e['status'] = Sisimai::SMTP::Status.code('expired') || e['status']
            end
          end

          e['lhost'] ||= permessage['rhost']
          e['command'] = commandtxt
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'SendGrid: https://sendgrid.com/'; end
    end
  end
end

