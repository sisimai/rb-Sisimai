module Sisimai::Lhost
  # Sisimai::Lhost::ApacheJames parses a bounce email which created by ApacheJames. Methods in the
  # module are called from only Sisimai::Message.
  module ApacheJames
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = {
        # apache-james-2.3.2/src/java/org/apache/james/transport/mailets/
        #   AbstractNotify.java|124:  out.println("Error message below:");
        #   AbstractNotify.java|128:  out.println("Message details:");
        message: [''],
        error:   ['Error message below:'],
      }.freeze

      # Parse bounce messages from Apache James
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        match  = 0
        match += 1 if mhead['subject'] == '[BOUNCE]'
        match += 1 if mhead['message-id'].to_s.include?('.JavaMail.')
        match += 1 if mhead['received'].any? { |a| a.include?('JAMES SMTP Server') }
        return nil unless match > 0

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        diagnostic = ''     # (String) Alternative diagnostic message
        subjecttxt = nil    # (String) Alternative Subject text
        gotmessage = nil    # (Boolean) Flag for error message
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

          # Message details:
          #   Subject: Nyaaan
          #   Sent date: Thu Apr 29 01:20:50 JST 2015
          #   MAIL FROM: shironeko@example.jp
          #   RCPT TO: kijitora@example.org
          #   From: Neko <shironeko@example.jp>
          #   To: kijitora@example.org
          #   Size (in bytes): 1024
          #   Number of lines: 64
          v = dscontents[-1]

          if cv = e.match(/\A[ ][ ]RCPT[ ]TO:[ ]([^ ]+[@][^ ]+)\z/)
            #   RCPT TO: kijitora@example.org
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            recipients += 1

          elsif cv = e.match(/\A[ ][ ]Sent[ ]date:[ ](.+)\z/)
            #   Sent date: Thu Apr 29 01:20:50 JST 2015
            v['date'] = cv[1]

          elsif cv = e.match(/\A[ ][ ]Subject:[ ](.+)\z/)
            #   Subject: Nyaaan
            subjecttxt = cv[1]
          else
            next if gotmessage
            if v['diagnosis']
              # Get an error message text
              if e.start_with?('Message details:')
                # Message details:
                #   Subject: nyaan
                #   ...
                gotmessage = true
              else
                # Append error message text like the followng:
                #   Error message below:
                #   550 - Requested action not taken: no such user here
                v['diagnosis'] << ' ' << e
              end
            else
              # Error message below:
              # 550 - Requested action not taken: no such user here
              v['diagnosis'] = e if e == StartingOf[:error][0]
              unless gotmessage
                v['diagnosis'] ||= ''
                v['diagnosis'] << ' ' + e
              end
            end
          end
        end
        return nil unless recipients > 0

        # Set the value of subjecttxt as a Subject if there is no original message in the bounce mail.
        emailsteak[1] << ('Subject: ' << subjecttxt << "\n") unless emailsteak[1] =~ /^Subject: /

        dscontents.each { |e| e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'] || diagnostic) }
        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Java Apache Mail Enterprise Server'; end
    end
  end
end

