module Sisimai::Lhost
  # Sisimai::Lhost::AmazonSES parses a bounce email which created by Amazon Simple Email Service.
  # Methods in the module are called from only Sisimai::Message.
  module AmazonSES
    class << self
      require 'sisimai/lhost'

      # https://aws.amazon.com/ses/
      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^content-type:[ ]message/rfc822|.freeze
      StartingOf = {
        message: ['The following message to <', 'An error occurred while trying to deliver the mail'],
      }.freeze
      MessagesOf = { 'expired' => ['Delivery expired'] }.freeze

      # Parse bounce messages from Amazon SES
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        recipients = 0  # (Integer) The number of 'Final-Recipient' header

        if mbody.start_with?('{')
          # The message body is JSON string
          return nil unless mhead['x-amz-sns-message-id']
          return nil if mhead['x-amz-sns-message-id'].empty?

          # https://docs.aws.amazon.com/en_us/ses/latest/DeveloperGuide/notification-contents.html
          bouncetype = {
            'Permanent' => { 'General' => '', 'NoEmail' => '', 'Suppressed' => '' },
            'Transient' => {
              'General'            => '',
              'MailboxFull'        => 'mailboxfull',
              'MessageTooLarge'    => 'mesgtoobig',
              'ContentRejected'    => '',
              'AttachmentRejected' => '',
            },
          }.freeze
          jsonstring = ''
          sespayload = nil
          foldedline = false
          bodyslices = mbody.split("\n")

          while e = bodyslices.shift do
            # Find JSON string from the message body
            next if e.empty?
            break if e == '--'

            # The line starts with " ", continued from !\n.
            e.lstrip! if foldedline
            foldedline = false

            if e.end_with?('!')
              # ... long long line ...![\n]
              e.chomp!('!')
              foldedline = true
            end
            jsonstring << e
          end

          begin
            if RUBY_PLATFORM.start_with?('java')
              # java-based ruby environment like JRuby.
              require 'jrjackson'
              jsonobject = JrJackson::Json.load(jsonstring)

              # 'Message' => '{"notificationType":"Bounce",...
              sespayload = JrJackson::Json.load(jsonobject['Message']) if jsonobject['Message']
            else
              # Matz' Ruby Implementation
              require 'oj'
              jsonobject = Oj.load(jsonstring)

              # 'Message' => '{"notificationType":"Bounce",...
              sespayload = Oj.load(jsonobject['Message']) if jsonobject['Message']
            end
            sespayload ||= jsonobject

          rescue StandardError => ce
            # Something wrong in decoding JSON
            warn ' ***warning: Failed to decode JSON: ' << ce.to_s
            return nil
          end

          rfc822head = {}   # (Hash) Check flags for headers in RFC822 part
          labeltable = {
            'Bounce'    => 'bouncedRecipients',
            'Complaint' => 'complainedRecipients',
          }
          p = sespayload
          v = nil

          if %w[Bounce Complaint].index(p['notificationType'])
            # { "notificationType":"Bounce", "bounce": { "bounceType":"Permanent",...
            o = p[p['notificationType'].downcase].dup
            r = o[labeltable[p['notificationType']]] || []

            while e = r.shift do
              # 'bouncedRecipients' => [ { 'emailAddress' => 'bounce@si...' }, ... ]
              # 'complainedRecipients' => [ { 'emailAddress' => 'complaint@si...' }, ... ]
              next unless Sisimai::Address.is_emailaddress(e['emailAddress'])

              v = dscontents[-1]
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              recipients += 1
              v['recipient'] = e['emailAddress']

              if p['notificationType'] == 'Bounce'
                # 'bouncedRecipients => [ {
                #   'emailAddress' => 'bounce@simulator.amazonses.com',
                #   'action' => 'failed',
                #   'status' => '5.1.1',
                #   'diagnosticCode' => 'smtp; 550 5.1.1 user unknown'
                # }, ... ]
                v['action'] = e['action']
                v['status'] = e['status']

                if cv = e['diagnosticCode'].match(/\A(.+?);[ ]*(.+)\z/)
                  # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                  v['spec'] = cv[1].upcase
                  v['diagnosis'] = cv[2]
                else
                  v['diagnosis'] = e['diagnosticCode']
                end

                # 'reportingMTA' => 'dsn; a27-23.smtp-out.us-west-2.amazonses.com',
                if cv = o['reportingMTA'].match(/\Adsn;[ ](.+)\z/) then v['lhost'] = cv[1] end

                if bouncetype[o['bounceType']] &&
                   bouncetype[o['bounceType']][o['bounceSubType']]
                  # 'bounce' => {
                  #   'bounceType'    => 'Permanent',
                  #   'bounceSubType' => 'General'
                  # },
                  v['reason'] = bouncetype[o['bounceType']][o['bounceSubType']]
                end
              else
                # 'complainedRecipients' => [ {
                #   'emailAddress' => 'complaint@simulator.amazonses.com' }, ... ],
                v['reason'] = 'feedback'
                v['feedbacktype'] = o['complaintFeedbackType'] || ''
              end

              v['date'] = o['timestamp'] || p['mail']['timestamp']
              v['date'].sub!(/[.]\d+Z\z/, '')
            end
          elsif p['notificationType'] == 'Delivery'
            # { "notificationType":"Delivery", "delivery": { ...
            o = p['delivery'].dup
            r = o['recipients'] || []

            while e = r.shift do
              # 'delivery' => {
              #   'timestamp' => '2016-11-23T12:01:03.512Z',
              #   'processingTimeMillis' => 3982,
              #   'reportingMTA' => 'a27-29.smtp-out.us-west-2.amazonses.com',
              #   'recipients' => [
              #     'success@simulator.amazonses.com'
              #   ],
              #   'smtpResponse' => '250 2.6.0 Message received'
              # },
              next unless Sisimai::Address.is_emailaddress(e)

              v = dscontents[-1]
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              recipients += 1
              v['recipient'] = e
              v['lhost']     = o['reportingMTA'] || ''
              v['diagnosis'] = o['smtpResponse'] || ''
              v['status']    = Sisimai::SMTP::Status.find(v['diagnosis']) || ''
              v['replycode'] = Sisimai::SMTP::Reply.find(v['diagnosis'])  || ''
              v['reason']    = 'delivered'
              v['action']    = 'delivered'

              v['date'] = o['timestamp'] || p['mail']['timestamp']
              v['date'].sub!(/[.]\d+Z\z/, '')
            end
          else
            # The value of "notificationType" is not any of "Bounce", "Complaint", or "Delivery".
            return nil
          end
          return nil unless recipients > 0

          if p['mail']['headers']
            # "headersTruncated":false,
            # "headers":[ { ...
            p['mail']['headers'].each do |e|
              # 'headers' => [ { 'name' => 'From', 'value' => 'neko@nyaan.jp' }, ... ],
              next unless %w[From To Subject Message-ID Date].index(e['name'])
              rfc822head[e['name'].downcase] = e['value']
            end
          end

          unless rfc822head['message-id']
            # Try to get the value of "Message-Id".
            if p['mail']['messageId']
              # 'messageId' => '01010157e48f9b9b-891e9a0e-9c9d-4773-9bfe-608f2ef4756d-000000'
              rfc822head['message-id'] = p['mail']['messageId']
            end
          end
          return { 'ds' => dscontents, 'rfc822' => rfc822head }

        else
          # The message body is an email
          # :from    => %r/\AMAILER-DAEMON[@]email[-]bounces[.]amazonses[.]com\z/,
          # :subject => %r/\ADelivery Status Notification [(]Failure[)]\z/,
          return nil if mhead['x-mailer'].to_s.start_with?('Amazon WorkMail')

          # X-SenderID: Sendmail Sender-ID Filter v1.0.0 nijo.example.jp p7V3i843003008
          # X-Original-To: 000001321defbd2a-788e31c8-2be1-422f-a8d4-cf7765cc9ed7-000000@email-bounces.amazonses.com
          # X-AWS-Outgoing: 199.255.192.156
          # X-SES-Outgoing: 2016.10.12-54.240.27.6
          match  = 0
          match += 1 if mhead['x-aws-outgoing']
          match += 1 if mhead['x-ses-outgoing']
          return nil unless match > 0

          require 'sisimai/rfc1894'
          fieldtable = Sisimai::RFC1894.FIELDTABLE
          permessage = {}     # (Hash) Store values of each Per-Message field

          emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
          bodyslices = emailsteak[0].split("\n")
          readslices = ['']
          readcursor = 0      # (Integer) Points the current cursor position
          v = nil

          while e = bodyslices.shift do
            # Read error messages and delivery status lines from the head of the email to the previous
            # line of the beginning of the original message.
            readslices << e # Save the current line for the next loop

            if readcursor == 0
              # Beginning of the bounce message or message/delivery-status part
              if e.start_with?(StartingOf[:message][0], StartingOf[:message][1])
                readcursor |= Indicators[:deliverystatus]
                next
              end
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
              # Continued line of the value of Diagnostic-Code field
              next unless readslices[-2].start_with?('Diagnostic-Code:')
              next unless cv = e.match(/\A[ \t]+(.+)\z/)
              v['diagnosis'] << ' ' << cv[1]
              readslices[-1] = 'Diagnostic-Code: ' << e
            end
          end

          if recipients == 0 && mbody =~ /notificationType/
            # Try to parse with Sisimai::Lhost::AmazonSES module
            j = Sisimai::Lhost::AmazonSES.json(mhead, mbody)

            if j['ds'].is_a? Array
              # Update dscontents
              dscontents = j['ds']
              recipients = j['ds'].size
            end
          end
          return nil unless recipients > 0

          dscontents.each do |e|
            # Set default values if each value is empty.
            e['lhost'] ||= permessage['rhost']
            permessage.each_key { |a| e[a] ||= permessage[a] || '' }

            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].to_s.tr("\n", ' '))
            if e['status'].to_s.start_with?('5.0.0', '5.1.0', '4.0.0', '4.1.0')
              # Get other D.S.N. value from the error message
              errormessage = e['diagnosis']

              if cv = e['diagnosis'].match(/["'](\d[.]\d[.]\d.+)['"]/)
                # 5.1.0 - Unknown address error 550-'5.7.1 ...
                errormessage = cv[1]
              end
              e['status'] = Sisimai::SMTP::Status.find(errormessage) || e['status']
            end

            MessagesOf.each_key do |r|
              # Verify each regular expression of session errors
              next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
              e['reason'] = r
              break
            end
          end

          return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
        end # END of a parser for email message

      end
      def description; return 'Amazon SES(Sending): https://aws.amazon.com/ses/'; end
    end
  end
end

