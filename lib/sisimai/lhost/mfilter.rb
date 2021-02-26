module Sisimai::Lhost
  # Sisimai::Lhost::mFILTER parses a bounce email which created by Digital Arts m-FILTER. Methods in
  # the module are called from only Sisimai::Message.
  module MFILTER
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r/^-------original[ ](?:message|mail[ ]info)/.freeze
      StartingOf = {
        error:   ['-------server message'],
        command: ['-------SMTP command'],
      }.freeze
      MarkingsOf = { message: %r/\A[^ ]+[@][^ ]+[.][a-zA-Z]+\z/ }.freeze

      # Parse bounce messages from Digital Arts m-FILTER
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # X-Mailer: m-FILTER
        return nil unless mhead['x-mailer'].to_s == 'm-FILTER'
        return nil unless mhead['subject'] == 'failure notice'

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        markingset = { 'diagnosis' => false, 'command' => false }
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e =~ MarkingsOf[:message]
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # このメールは「m-FILTER」が自動的に生成して送信しています。
          # メールサーバーとの通信中、下記の理由により
          # このメールは送信できませんでした。
          #
          # 以下のメールアドレスへの送信に失敗しました。
          # kijitora@example.jp
          #
          #
          # -------server message
          # 550 5.1.1 unknown user <kijitora@example.jp>
          #
          # -------SMTP command
          # DATA
          #
          # -------original message
          v = dscontents[-1]

          if cv = e.match(/\A([^ ]+[@][^ ]+)\z/)
            # 以下のメールアドレスへの送信に失敗しました。
            # kijitora@example.jp
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            recipients += 1

          elsif e =~ /\A[A-Z]{4}/
            # -------SMTP command
            # DATA
            next if v['command']
            v['command'] = e if markingset['command']
          else
            # Get error message and SMTP command
            if e == StartingOf[:error][0]
              # -------server message
              markingset['diagnosis'] = true

            elsif e == StartingOf[:command][0]
              # -------SMTP command
              markingset['command'] = true
            else
              # 550 5.1.1 unknown user <kijitora@example.jp>
              next if e.start_with?('-')
              next if v['diagnosis']
              v['diagnosis'] = e
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['agent'] = 'mFILTER'

          # Get localhost and remote host name from Received header.
          next if mhead['received'].empty?
          rheads = mhead['received']
          rhosts = Sisimai::RFC5322.received(rheads[-1])

          e['lhost'] ||= Sisimai::RFC5322.received(rheads[0]).shift
          while ee = rhosts.shift do
            # Avoid "... by m-FILTER"
            next unless ee.include?('.')
            e['rhost'] = ee
          end
        end
        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Digital Arts m-FILTER'; end
    end
  end
end

