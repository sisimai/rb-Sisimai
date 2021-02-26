module Sisimai::Lhost
  # Sisimai::Lhost::Zoho parses a bounce email which created by Zoho Mail. Methods in the module are
  # called from only Sisimai::Message.
  module Zoho
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Received:[ ]*from[ ]mail[.]zoho[.]com[ ]by[ ]mx[.]zohomail[.]com|.freeze
      StartingOf = { message: ['This message was created automatically by mail delivery'] }.freeze
      MessagesOf = { 'expired' => ['Host not reachable'] }.freeze

      # Parse bounce messages from Zoho Mail
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # X-ZohoMail: Si CHF_MF_NL SS_10 UW48 UB48 FMWL UW48 UB48 SGR3_1_09124_42
        # X-Zoho-Virus-Status: 2
        # X-Mailer: Zoho Mail
        return nil unless mhead['x-zohomail']

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        qprintable = false
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

          # This message was created automatically by mail delivery software.
          # A message that you sent could not be delivered to one or more of its recip=
          # ients. This is a permanent error.=20
          #
          # kijitora@example.co.jp Invalid Address, ERROR_CODE :550, ERROR_CODE :5.1.=
          # 1 <kijitora@example.co.jp>... User Unknown

          # This message was created automatically by mail delivery software.
          # A message that you sent could not be delivered to one or more of its recipients. This is a permanent error.
          #
          # shironeko@example.org Invalid Address, ERROR_CODE :550, ERROR_CODE :Requested action not taken: mailbox unavailable
          v = dscontents[-1]

          if cv = e.match(/\A([^ ]+[@][^ ]+)[ \t]+(.+)\z/)
            # kijitora@example.co.jp Invalid Address, ERROR_CODE :550, ERROR_CODE :5.1.=
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            v['diagnosis'] = cv[2]

            if v['diagnosis'].end_with?('=')
              # Quoted printable
              v['diagnosis'] = v['diagnosis'].chomp('=')
              qprintable = true
            end
            recipients += 1

          elsif cv = e.match(/\A\[Status: .+[<]([^ ]+[@][^ ]+)[>],/)
            # Expired
            # [Status: Error, Address: <kijitora@6kaku.example.co.jp>, ResponseCode 421, , Host not reachable.]
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            v['diagnosis'] = e
            recipients += 1
          else
            # Continued line
            next unless qprintable
            v['diagnosis'] << e
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].tr("\n", ' '))
          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Zoho Mail: https://www.zoho.com'; end
    end
  end
end

