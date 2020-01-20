module Sisimai::Lhost
  # Sisimai::Lhost::InterScanMSS parses a bounce email which created by
  # Trend Micro InterScan Messaging Security Suite. Methods in the module are
  # called from only Sisimai::Message.
  module InterScanMSS
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Lhost/InterScanMSS.pm
      require 'sisimai/lhost'

      ReBackbone = %r|^Content-type:[ ]message/rfc822|.freeze
      def description; return 'Trend Micro InterScan Messaging Security Suite'; end
      def smtpagent;   return Sisimai::Lhost.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from InterScanMSS
      # @param         [Hash] mhead       Message headers of a bounce email
      # @options mhead [String] from      From header
      # @options mhead [String] date      Date header
      # @options mhead [String] subject   Subject header
      # @options mhead [Array]  received  Received headers
      # @options mhead [String] others    Other required headers
      # @param         [String] mbody     Message body of a bounce email
      # @return        [Hash, Nil]        Bounce data list and message/rfc822
      #                                   part or nil if it failed to parse or
      #                                   the arguments are missing
      def make(mhead, mbody)
        # :received => %r/[ ][(]InterScanMSS[)][ ]with[ ]/,
        match = 0
        tryto = [
          'Mail could not be delivered',
          'メッセージを配信できません。',
          'メール配信に失敗しました',
        ]
        match += 1 if mhead['from'].start_with?('"InterScan MSS"')
        match += 1 if tryto.any? { |a| mhead['subject'] == a }
        return nil unless match > 0

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email
          # to the previous line of the beginning of the original message.
          next if e.empty?

          # Sent <<< RCPT TO:<kijitora@example.co.jp>
          # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
          v = dscontents[-1]

          if cv = e.match(/\A.+[<>]{3}[ \t]+.+[<]([^ ]+[@][^ ]+)[>]\z/) ||
                  e.match(/\A.+[<>]{3}[ \t]+.+[<]([^ ]+[@][^ ]+)[>]/)
            # Sent <<< RCPT TO:<kijitora@example.co.jp>
            # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
            if v['recipient'] && cv[1] != v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
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
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e.each_key { |a| e[a] ||= '' }
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end

    end
  end
end

