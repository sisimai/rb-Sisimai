module Sisimai::Lhost
  # Sisimai::Lhost::X1 parses a bounce email which created by Unknown MTA #1. Methods in the module
  # are called from only Sisimai::Message.
  module X1
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Received: from \d+[.]\d+[.]\d+[.]\d|.freeze
      MarkingsOf = { message: %r/\AThe original message was received at (.+)\z/ }.freeze

      # Parse bounce messages from Unknown MTA #1
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('Returned Mail: ')
        return nil unless mhead['from'].start_with?('"Mail Deliver System" ')

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        datestring = ''     # (String) Date string
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

          # The original message was received at Thu, 29 Apr 2010 23:34:45 +0900 (JST)
          # from shironeko@example.jp
          #
          # ---The following addresses had delivery errors---
          #
          # kijitora@example.co.jp [User unknown]
          v = dscontents[-1]

          if cv = e.match(/\A([^ ]+?[@][^ ]+?)[ ]+\[(.+)\]\z/)
            # kijitora@example.co.jp [User unknown]
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            v['diagnosis'] = cv[2]
            recipients += 1

          elsif cv = e.match(MarkingsOf[:message])
            # The original message was received at Thu, 29 Apr 2010 23:34:45 +0900 (JST)
            datestring = cv[1]
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['date']      = datestring || ''
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Unknown MTA #1'; end
    end
  end
end

