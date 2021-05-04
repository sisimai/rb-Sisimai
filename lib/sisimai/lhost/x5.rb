module Sisimai::Lhost
  # Sisimai::Lhost::X5 parses a bounce email which created by Unknown MTA #5. Methods in the module
  # are called from only Sisimai::Message.
  module X5
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = { message: ['Content-Type: message/delivery-status'] }.freeze

      # Parse bounce messages from Unknown MTA #5
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        match  = 0
        match += 1 if mhead['to'].to_s.include?('NotificationRecipients')
        if mhead['from'].include?('TWFpbCBEZWxpdmVyeSBTdWJzeXN0ZW0')
          # From: "=?iso-2022-jp?B?TWFpbCBEZWxpdmVyeSBTdWJzeXN0ZW0=?=" <...>
          #       Mail Delivery Subsystem
          mhead['from'].split(' ').each do |f|
            # Check each element of From: header
            next unless Sisimai::RFC2045.is_encoded(f)
            match += 1 if Sisimai::RFC2045.decodeH([f]).include?('Mail Delivery Subsystem')
            break
          end
        end

        if Sisimai::RFC2045.is_encoded(mhead['subject'])
          # Subject: =?iso-2022-jp?B?UmV0dXJuZWQgbWFpbDogVXNlciB1bmtub3du?=
          plain = Sisimai::RFC2045.decodeH([mhead['subject']])
          match += 1 if plain.include?('Mail Delivery Subsystem')
        end
        return nil if match < 2

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        readslices = ['']
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        # Pick the second message/rfc822 part because the format of email-x5-*.eml is nested structure
        prefillets = mbody.split(ReBackbone, 2)
        prefillets[1].sub!(/\A.+?\n\n/s, '')
        emailsteak = Sisimai::RFC5322.fillet(prefillets[1], ReBackbone)
        bodyslices = emailsteak[0].split("\n")

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

          v = dscontents[-1]
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
            end
          else
            # Continued line of the value of Diagnostic-Code field
            next unless readslices[-2].start_with?('Diagnostic-Code:')
            next unless cv = e.match(/\A[ \t]+(.+)\z/)
            v['diagnosis'] << ' ' << cv[1]
            readslices[-1] = 'Diagnostic-Code: ' << e
          end
        end
        return nil unless recipients > 0

        dscontents.each { |e| e['diagnosis'] ||= Sisimai::String.sweep(e['diagnosis']) }
        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Unknown MTA #5'; end
    end
  end
end

