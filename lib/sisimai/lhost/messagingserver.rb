module Sisimai::Lhost
  # Sisimai::Lhost::MessagingServer parses a bounce email which created by Oracle Communications Messaging
  # Server and Sun Java System Messaging Server. Methods in the module are called from only Sisimai::Message.
  module MessagingServer
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r<^(?:Content-type:[ ]*message/rfc822|Return-path:[ ]*)>.freeze
      StartingOf = { message: ['This report relates to a message you sent with the following header fields:'] }.freeze
      MessagesOf = { 'hostunknown' => ['Illegal host/domain name found'] }.freeze

      # Parse bounce messages from MessagingServer
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # :received => %r/[ ][(]MessagingServer[)][ ]with[ ]/,
        match  = 0
        match += 1 if mhead['content-type'].include?('Boundary_(ID_')
        match += 1 if mhead['subject'].start_with?('Delivery Notification: ')
        return nil unless match > 0

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

          # --Boundary_(ID_0000000000000000000000)
          # Content-type: text/plain; charset=us-ascii
          # Content-language: en-US
          #
          # This report relates to a message you sent with the following header fields:
          #
          #   Message-id: <CD8C6134-C312-41D5-B083-366F7FA1D752@me.example.com>
          #   Date: Fri, 21 Nov 2014 23:34:45 +0900
          #   From: Shironeko <shironeko@me.example.com>
          #   To: kijitora@example.jp
          #   Subject: Nyaaaaaaaaaaaaaaaaaaaaaan
          #
          # Your message cannot be delivered to the following recipients:
          #
          #   Recipient address: kijitora@example.jp
          #   Reason: Remote SMTP server has rejected address
          #   Diagnostic code: smtp;550 5.1.1 <kijitora@example.jp>... User Unknown
          #   Remote system: dns;mx.example.jp (TCP|17.111.174.67|47323|192.0.2.225|25) (6jo.example.jp ESMTP SENDMAIL-VM)
          v = dscontents[-1]

          if cv = e.match(/\A[ \t]+Recipient address:[ \t]*([^ ]+[@][^ ]+)\z/)
            #   Recipient address: kijitora@example.jp
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = Sisimai::Address.s3s4(cv[1])
            recipients += 1

          elsif cv = e.match(/\A[ \t]+Original address:[ \t]*([^ ]+[@][^ ]+)\z/)
            #   Original address: kijitora@example.jp
            v['recipient'] = Sisimai::Address.s3s4(cv[1])

          elsif cv = e.match(/\A[ \t]+Date:[ \t]*(.+)\z/)
            #   Date: Fri, 21 Nov 2014 23:34:45 +0900
            v['date'] = cv[1]

          elsif cv = e.match(/\A[ \t]+Reason:[ \t]*(.+)\z/)
            #   Reason: Remote SMTP server has rejected address
            v['diagnosis'] = cv[1]

          elsif cv = e.match(/\A[ \t]+Diagnostic code:[ \t]*([^ ]+);(.+)\z/)
            #   Diagnostic code: smtp;550 5.1.1 <kijitora@example.jp>... User Unknown
            v['spec'] = cv[1].upcase
            v['diagnosis'] = cv[2]

          elsif cv = e.match(/\A[ \t]+Remote system:[ ]*dns;([^ ]+)[ ]*([^ ]+)[ ]*.+\z/)
            #   Remote system: dns;mx.example.jp (TCP|17.111.174.67|47323|192.0.2.225|25)
            #     (6jo.example.jp ESMTP SENDMAIL-VM)
            remotehost = cv[1]  # remote host
            sessionlog = cv[2]  # smtp session
            v['rhost'] = remotehost

            # The value does not include ".", use IP address instead.
            # (TCP|17.111.174.67|47323|192.0.2.225|25)
            next unless cv = sessionlog.match(/\A[(]TCP|(.+)|\d+|(.+)|\d+[)]/)
            v['lhost'] = cv[1]
            v['rhost'] = cv[2] unless remotehost =~ /[^.]+[.][^.]+/
          else
            # Original-envelope-id: 0NFC009FLKOUVMA0@mr21p30im-asmtp004.me.com
            # Reporting-MTA: dns;mr21p30im-asmtp004.me.com (tcp-daemon)
            # Arrival-date: Thu, 29 Apr 2014 23:34:45 +0000 (GMT)
            #
            # Original-recipient: rfc822;kijitora@example.jp
            # Final-recipient: rfc822;kijitora@example.jp
            # Action: failed
            # Status: 5.1.1 (Remote SMTP server has rejected address)
            # Remote-MTA: dns;mx.example.jp (TCP|17.111.174.67|47323|192.0.2.225|25)
            #  (6jo.example.jp ESMTP SENDMAIL-VM)
            # Diagnostic-code: smtp;550 5.1.1 <kijitora@example.jp>... User Unknown
            #
            if cv = e.match(/\AStatus:[ ]*(\d[.]\d[.]\d)[ ]*[(](.+)[)]\z/)
              # Status: 5.1.1 (Remote SMTP server has rejected address)
              v['status'] = cv[1]
              v['diagnosis'] ||= cv[2]

            elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
              # Arrival-date: Thu, 29 Apr 2014 23:34:45 +0000 (GMT)
              v['date'] ||= cv[1]

            elsif cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
              # Reporting-MTA: dns;mr21p30im-asmtp004.me.com (tcp-daemon)
              localhost = cv[1]
              v['lhost'] ||= localhost
              v['lhost']   = localhost unless v['lhost'] =~ /[^.]+[.][^ ]+/
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Oracle Communications Messaging Server'; end
    end
  end
end

