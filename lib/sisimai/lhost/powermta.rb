module Sisimai::Lhost
  # Sisimai::Lhost::PowerMTA parses a bounce email which created by PowerMTA. Methods in the module
  # are called from only Sisimai::Message.
  module PowerMTA
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]text/rfc822-headers|.freeze
      StartingOf = { message: ['Hello, this is the mail server on '] }.freeze
      Categories = {
        'bad-domain'          => 'hostunknown',
        'bad-mailbox'         => 'userunknown',
        'inactive-mailbox'    => 'disabled',
        'message-expired'     => 'expired',
        'no-answer-from-host' => 'networkerror',
        'policy-related'      => 'policyviolation',
        'quota-issues'        => 'mailboxfull',
        'routing-errors'      => 'systemerror',
        'spam-related'        => 'spamdetected',
      }.freeze

      # Parse bounce messages from PowerMTA
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      # @since v4.25.6
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].to_s.start_with?('Delivery report')

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

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
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          if f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            next unless o = Sisimai::RFC1894.field(e)
            v = dscontents[-1]

            if o[-1] == 'addr'
              # Final-Recipient: rfc822; kijitora@example.jp
              # X-Actual-Recipient: rfc822; kijitora@example.co.jp
              if o[0] == 'final-recipient'
                # Final-Recipient: rfc822; kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Lhost.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = o[2]
                recipients += 1
              else
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                v['alias'] = o[2]
              end
            elsif o[-1] == 'code'
              # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
              v['spec'] = o[1]
              v['diagnosis'] = o[2]
            else
              # Other DSN fields defined in RFC3464
              next unless fieldtable[o[0]]
              v[fieldtable[o[0]]] = o[2]

              next unless f == 1
              permessage[fieldtable[o[0]]] = o[2]
            end
          else
            # Hello, this is the mail server on neko2.example.org.
            #
            # I am sending you this message to inform you on the delivery status of a
            # message you previously sent.  Immediately below you will find a list of
            # the affected recipients;  also attached is a Delivery Status Notification
            # (DSN) report in standard format, as well as the headers of the original
            # message.
            #
            #  <kijitora@example.jp>  delivery failed; will not continue trying
            #
            if cv = e.match(/\AX-PowerMTA-BounceCategory:[ ]*(.+)\z/)
              # X-PowerMTA-BounceCategory: bad-mailbox
              v['category'] = cv[1]
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].to_s.tr("\n", ' '))
          e['reason']    = Categories[e['category']] || ''
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'PowerMTA: https://www.sparkpost.com/powermta/'; end
    end
  end
end

