module Sisimai::Lhost
  # Sisimai::Lhost::X6 parses a bounce email which created by Unknown MTA #6. Methods in the module
  # are called from only Sisimai::Message.
  module X6
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r/^The attachment contains the original mail headers.+$/.freeze
      MarkingsOf = { message: %r/\A\d+[ ]*error[(]s[)]:/ }.freeze

      # Parse bounce messages from Unknown MTA #6
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      # @since v4.25.6
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('There was an error sending your mail')

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
            readcursor |= Indicators[:deliverystatus] if e =~ MarkingsOf[:message]
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # 1 error(s):
          #
          # SMTP Server <mta2.example.jp> rejected recipient <kijitora@examplejp> 
          #   (Error following RCPT command). It responded as follows: [550 5.1.1 User unknown]v = dscontents[-1]
          v = dscontents[-1]
          if cv = e.match(/<([^ @]+[@][^ @]+)>/) || e.match(/errors:[ ]*([^ ]+[@][^ ]+)/)
            # SMTP Server <mta2.example.jp> rejected recipient <kijitora@examplejp> 
            # The following recipients returned permanent errors: neko@example.jp.
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = Sisimai::Address.s3s4(cv[1])
            v['diagnosis'] = e
            recipients += 1
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          if cv = e['diagnosis'].match(/\b(HELO|EHLO|MAIL|RCPT|DATA)\b/)
            # ...(Error following RCPT command).
            e['command'] = cv[1]
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Unknown MTA #6'; end
    end
  end
end

