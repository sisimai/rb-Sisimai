module Sisimai::Lhost
  # Sisimai::Lhost::IMailServer parses a bounce email which created by Ipswitch IMail Server.
  # Methods in the module are called from only Sisimai::Message.
  module IMailServer
    class << self
      require 'sisimai/lhost'

      ReBackbone = %r|^Original[ ]message[ ]follows[.]|.freeze
      StartingOf = { error: ['Body of message generated response:'] }.freeze

      ReSMTP = {
        'conn' => %r/(?:SMTP connection failed,|Unexpected connection response from server:)/,
        'ehlo' => %r|Unexpected response to EHLO/HELO:|,
        'mail' => %r|Server response to MAIL FROM:|,
        'rcpt' => %r|Additional RCPT TO generated following response:|,
        'data' => %r|DATA command generated response:|,
      }.freeze
      ReFailures = {
        'hostunknown'   => %r/Unknown host/,
        'userunknown'   => %r/\A(?:Unknown user|Invalid final delivery userid)/,
        'mailboxfull'   => %r/\AUser mailbox exceeds allowed size/,
        'securityerror' => %r/\ARequested action not taken: virus detected/,
        'undefined'     => %r/\Aundeliverable to /,
        'expired'       => %r/\ADelivery failed \d+ attempts/,
      }.freeze

      # Parse bounce messages from IMailServer
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # X-Mailer: <SMTP32 v8.22>
        match  = 0
        match += 1 if mhead['subject'] =~ /\AUndeliverable Mail[ ]*\z/
        match += 1 if mhead['x-mailer'].to_s.start_with?('<SMTP32 v')
        return nil unless match > 0

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.

          # Unknown user: kijitora@example.com
          #
          # Original message follows.
          v = dscontents[-1]

          if cv = e.match(/\A([^ ]+)[ ](.+)[:][ \t]*([^ ]+[@][^ ]+)/)
            # Unknown user: kijitora@example.com
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['diagnosis'] = cv[1] + ' ' + cv[2]
            v['recipient'] = cv[3]
            recipients += 1

          elsif cv = e.match(/\Aundeliverable[ ]+to[ ]+(.+)\z/)
            # undeliverable to kijitora@example.com
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = Sisimai::Address.s3s4(cv[1])
            recipients += 1
          else
            # Other error message text
            v['alterrors'] << ' ' << e if v['alterrors']
            v['alterrors'] = e if e.include?(StartingOf[:error][0])
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          unless e['alterrors'].to_s.empty?
            # Copy alternative error message
            e['diagnosis'] = if e['diagnosis']
                               e['alterrors'] + ' ' + e['diagnosis']
                             else
                               e['alterrors']
                             end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e.delete('alterrors')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          ReSMTP.each_key do |r|
            # Detect SMTP command from the message
            next unless e['diagnosis'] =~ ReSMTP[r]
            e['command'] = r.upcase
            break
          end

          ReFailures.each_key do |r|
            # Verify each regular expression of session errors
            next unless e['diagnosis'] =~ ReFailures[r]
            e['reason'] = r
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'IPSWITCH IMail Server'; end
    end
  end
end

