module Sisimai::Lhost
  # Sisimai::Lhost::Notes parses a bounce email which created by Lotus Notes Server. Methods in the
  # module are called from only Sisimai::Message.
  module Notes
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^-------[ ]Returned[ ]Message[ ]--------|.freeze
      StartingOf = { message: ['------- Failure Reasons '] }.freeze
      MessagesOf = {
        'userunknown' => [
          'User not listed in public Name & Address Book',
          'ディレクトリのリストにありません',
        ],
        'networkerror' => ['Message has exceeded maximum hop count'],
      }.freeze

      # Parse bounce messages from Lotus Notes
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('Undeliverable message')

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        characters = ''     # (String) Character set name of the bounce mail
        removedmsg = 'MULTIBYTE CHARACTERS HAVE BEEN REMOVED'
        encodedmsg = ''
        v = nil

        if cv = mhead['content-type'].match(/\A.+;[ ]*charset=(.+)\z/)
          # Get character set name
          # Content-Type: text/plain; charset=ISO-2022-JP
          characters = cv[1].downcase
        end

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0

          # ------- Failure Reasons  --------
          #
          # User not listed in public Name & Address Book
          # kijitora@notes.example.jp
          #
          # ------- Returned Message --------
          v = dscontents[-1]
          if e =~ /\A[^ ]+[@][^ ]+/
            # kijitora@notes.example.jp
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] ||= e
            recipients += 1
          else
            next if e.empty?
            next if e.start_with?('-')

            if e =~ /[^\x20-\x7e]/
              # Error message is not ISO-8859-1
              if characters.size > 0
                # Try to convert string
                begin
                  encodedmsg = e.encode('UTF-8', characters)
                rescue
                  # Failed to convert
                  encodedmsg = removedmsg
                end
              else
                # No character set in Content-Type header
                encodedmsg = removedmsg
              end
              v['diagnosis'] ||= ''
              v['diagnosis'] << encodedmsg
            else
              # Error message does not include multi-byte character
              v['diagnosis'] ||= ''
              v['diagnosis'] << e
            end
          end
        end

        unless recipients > 0
          # Fallback: Get the recpient address from RFC822 part
          if cv = emailsteak[1].match(/^To:[ ]*(.+)$/)
            v['recipient'] = Sisimai::Address.s3s4(cv[1])
            recipients += 1 unless v['recipient'].empty?
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['recipient'] = Sisimai::Address.s3s4(e['recipient'])

          MessagesOf.each_key do |r|
            # Check each regular expression of Notes error messages
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r
            e['status'] = Sisimai::SMTP::Status.code(r.to_s) || ''
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Lotus Notes'; end
    end
  end
end

