module Sisimai::Lhost
  # Sisimai::Lhost::X3 parses a bounce email which created by Unknown MTA #3. Methods in the module
  # are called from only Sisimai::Message.
  module X3
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = { message: ['      This is an automatically generated Delivery Status Notification.'] }.freeze

      # Parse bounce messages from Unknown MTA #3
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('Delivery status notification')
        return nil unless mhead['from'].start_with?('Mail Delivery System')

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

          # ============================================================================
          #      This is an automatically generated Delivery Status Notification.
          #
          # Delivery to the following recipients failed permanently:
          #
          #   * kijitora@example.com
          #
          #
          # ============================================================================
          #                             Technical details:
          #
          # SMTP:RCPT host 192.0.2.8: 553 5.3.0 <kijitora@example.com>... No such user here
          #
          #
          # ============================================================================
          v = dscontents[-1]

          if cv = e.match(/\A[ \t]+[*][ ]([^ ]+[@][^ ]+)\z/)
            #   * kijitora@example.com
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            recipients += 1
          else
            # Detect error message
            if cv = e.match(/\ASMTP:([^ ]+)[ ](.+)\z/)
              # SMTP:RCPT host 192.0.2.8: 553 5.3.0 <kijitora@example.com>... No such user here
              v['command'] = cv[1].upcase
              v['diagnosis'] = cv[2]

            elsif cv = e.match(/\ARouting: (.+)/)
              # Routing: Could not find a gateway for kijitora@example.co.jp
              v['diagnosis'] = cv[1]

            elsif cv = e.match(/\ADiagnostic-Code: smtp; (.+)/)
              # Diagnostic-Code: smtp; 552 5.2.2 Over quota
              v['diagnosis'] = cv[1]
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['status']    = Sisimai::SMTP::Status.find(e['diagnosis']) || ''
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Unknown MTA #3'; end
    end
  end
end

