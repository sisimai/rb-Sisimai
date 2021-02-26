module Sisimai::Lhost
  # Sisimai::Lhost::InterScanMSS parses a bounce email which created by Trend Micro InterScan Messaging
  # Security Suite. Methods in the module are called from only Sisimai::Message.
  module InterScanMSS
    class << self
      require 'sisimai/lhost'
      ReBackbone = %r|^Content-type:[ ]message/rfc822|.freeze

      # Parse bounce messages from InterScanMSS
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # :received => %r/[ ][(]InterScanMSS[)][ ]with[ ]/,
        match = 0
        tryto = [
          'Mail could not be delivered',
          'メッセージを配信できません。',
          'メール配信に失敗しました',
        ]
        match += 1 if mhead['from'].start_with?('"InterScan MSS"')
        match += 1 if mhead['from'].start_with?('"InterScan Notification"')
        match += 1 if tryto.any? { |a| mhead['subject'] == a }
        return nil unless match > 0

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          next if e.empty?

          v = dscontents[-1]
          if cv = e.match(/\A.+[<>]{3}[ \t]+.+[<]([^ ]+[@][^ ]+)[>]\z/) ||
                  e.match(/\A.+[<>]{3}[ \t]+.+[<]([^ ]+[@][^ ]+)[>]/)   ||
                  e.match(/\A(?:Reason:[ ]+)?Unable[ ]to[ ]deliver[ ]message[ ]to[ ][<](.+)[>]/)
            # Sent <<< RCPT TO:<kijitora@example.co.jp>
            # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
            # Unable to deliver message to <kijitora@neko.example.jp>
            if v['recipient'] && cv[1] != v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            v['diagnosis'] = e if e =~ /Unable[ ]to[ ]deliver[ ]/
            recipients = dscontents.size
          end

          if cv = e.match(/\ASent[ ]+[<]{3}[ ]+([A-Z]{4})[ ]/)
            # Sent <<< RCPT TO:<kijitora@example.co.jp>
            v['command'] = cv[1]

          elsif cv = e.match(/\AReceived[ ]+[>]{3}[ ]+(\d{3}[ ]+.+)\z/)
            # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
            v['diagnosis'] = cv[1]
          else
            # Error message in non-English
            if cv = e.match(/[ ][>]{3}[ ]([A-Z]{4})/)
              # >>> RCPT TO ...
              v['command'] = cv[1]

            elsif cv = e.match(/[ ][<]{3}[ ](.+)/)
              # <<< 550 5.1.1 User unknown
              v['diagnosis'] = cv[1]
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['reason'] = 'userunknown' if e['diagnosis'] =~ /Unable[ ]to[ ]deliver/
        end
        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Trend Micro InterScan Messaging Security Suite'; end
    end
  end
end

