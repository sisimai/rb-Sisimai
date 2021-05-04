module Sisimai::Lhost
  # Sisimai::Lhost::MailRu parses a bounce email which created by @mail.ru. Methods in the module are
  # called from only Sisimai::Message.
  module MailRu
    class << self
      # Based on Sisimai::Lhost::Exim
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^------ This is a copy of the message, including all the headers[.] ------|.freeze
      StartingOf = { message: ['This message was created automatically by mail delivery software.'] }.freeze
      ReCommands = [
        %r/SMTP error from remote (?:mail server|mailer) after ([A-Za-z]{4})/,
        %r/SMTP error from remote (?:mail server|mailer) after end of ([A-Za-z]{4})/,
      ].freeze
      MessagesOf = {
        'expired' => [
          'retry timeout exceeded',
          'No action is required on your part',
        ],
        'userunknown' => ['user not found'],
        'hostunknown' => [
          'all host address lookups failed permanently',
          'all relevant MX records point to non-existent hosts',
          'Unrouteable address',
        ],
        'mailboxfull' => ['mailbox is full', 'error: quota exceed'],
        'notaccept' => [
          'an MX or SRV record indicated no SMTP service',
          'no host found for existing SMTP connection',
        ],
        'syntaxerror' => [
          'angle-brackets nested too deep',
          'expected word or "<"',
          'domain missing in source-routed address',
          'malformed address:',
        ],
        'systemerror' => [
          'delivery to file forbidden',
          'delivery to pipe forbidden',
          'local delivery failed',
          'LMTP error after ',
        ],
        'contenterror' => ['Too many "Received" headers'],
      }.freeze

      # Parse bounce messages from @mail.ru
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['from'] =~ /[<]?mailer-daemon[@].*mail[.]ru[>]?/i
        return nil unless mhead['message-id'].end_with?('.mail.ru>', 'smailru.net>')
        return nil unless mhead['subject'] =~ %r{(?:
           Mail[ ]delivery[ ]failed(:[ ]returning[ ]message[ ]to[ ]sender)?
          |Warning:[ ]message[ ].+[ ]delayed[ ]+
          |Delivery[ ]Status[ ]Notification
          |Mail[ ]failure
          |Message[ ]frozen
          |error[(]s[)][ ]in[ ]forwarding[ ]or[ ]filtering
          )
        }x

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        localhost0 = ''     # (String) Local MTA
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

          # Это письмо создано автоматически
          # сервером Mail.Ru, # отвечать на него не
          # нужно.
          #
          # К сожалению, Ваше письмо не может
          # быть# доставлено одному или нескольким
          # получателям:
          #
          # **********************
          #
          # This message was created automatically by mail delivery software.
          #
          # A message that you sent could not be delivered to one or more of its
          # recipients. This is a permanent error. The following address(es) failed:
          #
          #  kijitora@example.jp
          #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
          #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
          v = dscontents[-1]

          if cv = e.match(/\A[ \t]+([^ \t]+[@][^ \t]+[.][a-zA-Z]+)\z/)
            #   kijitora@example.jp
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            recipients += 1

          elsif dscontents.size == recipients
            # Error message
            next if e.empty?
            v['diagnosis'] ||= ''
            v['diagnosis'] << e + ' '
          else
            # Error message when email address above does not include '@'
            # and domain part.
            next unless e.start_with?('    ', "\t")
            v['alterrors'] ||= ''
            v['alterrors'] << e + ' '
          end
        end

        unless recipients > 0
          # Fallback for getting recipient addresses
          if mhead['x-failed-recipients']
            # X-Failed-Recipients: kijitora@example.jp
            rcptinhead = mhead['x-failed-recipients'].split(',')
            rcptinhead.each { |a| a.delete(' ') }
            recipients = rcptinhead.size

            while e = rcptinhead.shift do
              # Insert each recipient address into dscontents
              dscontents[-1]['recipient'] = e
              next if dscontents.size == recipients
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
            end
          end
        end
        return nil unless recipients > 0

        unless mhead['received'].empty?
          # Get the name of local MTA
          # Received: from marutamachi.example.org (c192128.example.net [192.0.2.128])
          if cv = mhead['received'][-1].match(/from[ \t]([^ ]+)/) then localhost0 = cv[1] end
        end

        dscontents.each do |e|
          # Set default values if each value is empty.
          e['lhost'] ||= localhost0

          unless e['alterrors'].to_s.empty?
            # Copy alternative error message
            e['diagnosis'] ||= e['alterrors']
            if e['diagnosis'].start_with?('-') || e['diagnosis'].end_with?('__')
              # Override the value of diagnostic code message
              e['diagnosis'] = e['alterrors'] unless e['alterrors'].empty?
            end
            e.delete('alterrors')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''
          e['diagnosis'].sub!(/\b__.+\z/, '')

          unless e['rhost']
            # Get the remote host name
            # host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
            if cv = e['diagnosis'].match(/host[ ]+([^ \t]+)[ ]\[.+\]:[ ]/) then e['rhost'] = cv[1] end

            unless e['rhost']
              # Get localhost and remote host name from Received header.
              e['rhost'] = Sisimai::RFC5322.received(mhead['received'][-1]).pop unless mhead['received'].empty?
            end
          end

          unless e['command']
            # Get the SMTP command name for the session
            ReCommands.each do |r|
              # Verify each regular expression of SMTP commands
              if cv = e['diagnosis'].match(r)
                e['command'] = cv[1].upcase
                break
              end
            end

            # Detect the reason of bounce
            if %w[HELO EHLO].index(e['command'])
              # HELO | Connected to 192.0.2.135 but my name was rejected.
              e['reason'] = 'blocked'

            elsif e['command'] == 'MAIL'
              # MAIL | Connected to 192.0.2.135 but sender was rejected.
              e['reason'] = 'rejected'
            else
              # Verify each regular expression of session errors
              MessagesOf.each_key do |r|
                # Check each regular expression
                next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
                e['reason'] = r
                break
              end
            end
          end
          e['command'] ||= ''
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return '@mail.ru: https://mail.ru'; end
    end
  end
end

