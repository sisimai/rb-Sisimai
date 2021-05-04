module Sisimai::Lhost
  # Sisimai::Lhost::McAfee parses a bounce email which created by McAfee Email Appliance. Methods in
  # the module are called from only Sisimai::Message.
  module McAfee
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = { message: ['--- The following addresses had delivery problems ---'] }.freeze
      ReFailures = {
        'userunknown' => %r{(?:
           [ ]User[ ][(].+[@].+[)][ ]unknown[.][ ]
          |550[ ]Unknown[ ]user[ ][^ ]+[@][^ ]+
          |550[ ][<].+?[@].+?[>][.]+[ ]User[ ]not[ ]exist
          |No[ ]such[ ]user
          )
        }x,
      }.freeze

      # Parse bounce messages from McAfee Email Appliance
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # X-NAI-Header: Modified by McAfee Email and Web Security Virtual Appliance
        return nil unless mhead['x-nai-header']
        return nil unless mhead['x-nai-header'].start_with?('Modified by McAfee ')
        return nil unless mhead['subject'] == 'Delivery Status'

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readslices = ['']
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        diagnostic = ''     # (String) Alternative diagnostic message
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.include?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # Content-Type: text/plain; name="deliveryproblems.txt"
          #
          #    --- The following addresses had delivery problems ---
          #
          # <user@example.com>   (User unknown user@example.com)
          #
          # --------------Boundary-00=_00000000000000000000
          # Content-Type: message/delivery-status; name="deliverystatus.txt"
          #
          v = dscontents[-1]

          if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>][ \t]+[(](.+)[)]\z/)
            # <kijitora@example.co.jp>   (Unknown user kijitora@example.co.jp)
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            diagnostic = cv[2]
            recipients += 1

          elsif f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            o = Sisimai::RFC1894.field(e)
            unless o
              # Fallback code for empty value or invalid formatted value
              # - Original-Recipient: <kijitora@example.co.jp>
              if cv = e.match(/\AOriginal-Recipient:[ ]*([^ ]+)\z/)
                v['alias'] = Sisimai::Address.s3s4(cv[1])
              end
              next
            end
            next unless fieldtable[o[0]]
            v[fieldtable[o[0]]] = o[2]

          else
            # Continued line of the value of Diagnostic-Code field
            next unless readslices[-2].start_with?('Diagnostic-Code:')
            next unless cv = e.match(/\A[ \t]+(.+)\z/)
            v['diagnosis'] << ' ' << cv[1]
            readslices[-1] = 'Diagnostic-Code: ' << e
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'] || diagnostic)
          ReFailures.each_key do |r|
            # Verify each regular expression of session errors
            next unless e['diagnosis'] =~ ReFailures[r]
            e['reason'] = r
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'McAfee Email Appliance'; end
    end
  end
end

