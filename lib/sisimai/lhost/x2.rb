module Sisimai::Lhost
  # Sisimai::Lhost::X2 parses a bounce email which created by Unknown MTA #2. Methods in the module
  # are called from only Sisimai::Message.
  module X2
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^--- Original message follows[.]|.freeze
      StartingOf = { message: ['Unable to deliver message to the following address'] }.freeze

      # Parse bounce messages from Unknown MTA #2
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['from'].include?('MAILER-DAEMON@')
        return nil unless mhead['subject'] =~ %r/\A(?>Delivery failure|fail(?:ure|ed) delivery)/

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

          # Message from example.com.
          # Unable to deliver message to the following address(es).
          #
          # <kijitora@example.com>:
          # This user doesn't have a example.com account (kijitora@example.com) [0]
          v = dscontents[-1]

          if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>]:\z/)
            # <kijitora@example.com>:
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            recipients += 1
          else
            # This user doesn't have a example.com account (kijitora@example.com) [0]
            v['diagnosis'] ||= ''
            v['diagnosis'] << ' ' << e
          end
        end
        return nil unless recipients > 0

        dscontents.each { |e| e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) }
        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Unknown MTA #2'; end
    end
  end
end

