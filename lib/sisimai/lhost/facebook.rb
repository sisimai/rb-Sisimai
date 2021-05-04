module Sisimai::Lhost
  # Sisimai::Lhost::Facebook parses a bounce email which created by Facebook. Methods in the module
  # are called from only Sisimai::Message.
  module Facebook
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Disposition:[ ]inline|.freeze
      StartingOf = { message: ['This message was created automatically by Facebook.'] }.freeze
      ReFailures = {
        # http://postmaster.facebook.com/response_codes
        # NOT TESTD EXCEPT RCP-P2
        'userunknown' => [
          'RCP-P1', # The attempted recipient address does not exist.
          'INT-P1', # The attempted recipient address does not exist.
          'INT-P3', # The attempted recpient group address does not exist.
          'INT-P4', # The attempted recipient address does not exist.
        ],
        'filtered' => [
          'RCP-P2', # The attempted recipient's preferences prevent messages from being delivered.
          'RCP-P3', # The attempted recipient's privacy settings blocked the delivery.
        ],
        'mesgtoobig' => [
          'MSG-P1', # The message exceeds Facebook's maximum allowed size.
          'INT-P2', # The message exceeds Facebook's maximum allowed size.
        ],
        'contenterror' => [
          'MSG-P2', # The message contains an attachment type that Facebook does not accept.
          'MSG-P3', # The message contains multiple instances of a header field that can only be present once. Please see RFC 5322, section 3.6 for more information
          'POL-P6', # The message contains a url that has been blocked by Facebook.
          'POL-P7', # The message does not comply with Facebook's abuse policies and will not be accepted.
        ],
        'securityerror' => [
          'POL-P1', # Your mail server's IP Address is listed on the Spamhaus PBL.
          'POL-P2', # Facebook will no longer accept mail from your mail server's IP Address.
          'POL-P5', # The message contains a virus.
          'POL-P7', # The message does not comply with Facebook's Domain Authentication requirements.
        ],
        'notaccept' => [
          'POL-P3', # Facebook is not accepting messages from your mail server. This will persist for 4 to 8 hours.
          'POL-P4', # Facebook is not accepting messages from your mail server. This will persist for 24 to 48 hours.
          'POL-T1', # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 1 to 2 hours.
          'POL-T2', # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 4 to 8 hours.
          'POL-T3', # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 24 to 48 hours.
        ],
        'rejected' => [
          'DNS-P1', # Your SMTP MAIL FROM domain does not exist.
          'DNS-P2', # Your SMTP MAIL FROM domain does not have an MX record.
          'DNS-T1', # Your SMTP MAIL FROM domain exists but does not currently resolve.
          'DNS-P3', # Your mail server does not have a reverse DNS record.
          'DNS-T2', # You mail server's reverse DNS record does not currently resolve.
        ],
        'systemerror' => [
          'CON-T1', # Facebook's mail server currently has too many connections open to allow another one.
        ],
        'toomanyconn' => [
          'CON-T3', # Your mail server has opened too many new connections to Facebook's mail servers in a short period of time.
        ],
        'suspend' => [
          'RCP-T4', # The attempted recipient address is currently deactivated. The user may or may not reactivate it.
        ],
        'undefined' => [
          'RCP-T1', # The attempted recipient address is not currently available due to an internal system issue. This is a temporary condition.
          'MSG-T1', # The number of recipients on the message exceeds Facebook's allowed maximum.
          'CON-T2', # Your mail server currently has too many connections open to Facebook's mail servers.
          'CON-T4', # Your mail server has exceeded the maximum number of recipients for its current connection.
        ],
      }.freeze

      # Parse bounce messages from Facebook
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['from'] == 'Facebook <mailer-daemon@mx.facebook.com>'
        return nil unless mhead['subject'] == 'Sorry, your message could not be delivered'

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readslices = ['']
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        fbresponse = ''     # (String) Response code from Facebook
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e == StartingOf[:message][0]
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          if f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            o = Sisimai::RFC1894.field(e) || next
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
        return nil unless recipients > 0

        dscontents.each do |e|
          e['lhost']   ||= permessage['lhost']
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          if cv = e['diagnosis'].match(/\b([A-Z]{3})[-]([A-Z])(\d)\b/)
            # Diagnostic-Code: smtp; 550 5.1.1 RCP-P2
            lhs = cv[1]
            rhs = cv[2]
            num = cv[3]

            fbresponse = sprintf('%s-%s%d', lhs, rhs, num)
          end

          catch :SESSION do
            ReFailures.each_key do |r|
              # Verify each regular expression of session errors
              ReFailures[r].each do |rr|
                # Check each regular expression
                next unless fbresponse == rr
                e['reason'] = r
                throw :SESSION
              end
            end
          end

          # http://postmaster.facebook.com/response_codes
          #   Facebook System Resource Issues
          #   These codes indicate a temporary issue internal to Facebook's
          #   system. Administrators observing these issues are not required to
          #   take any action to correct them.
          next if e['reason']

          # * INT-Tx
          #
          # https://groups.google.com/forum/#!topic/cdmix/eXfi4ddgYLQ
          # This block has not been tested because we have no email sample
          # including "INT-T?" error code.
          next unless fbresponse =~ /\AINT-T\d+\z/
          e['reason'] = 'systemerror'
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Facebook: https://www.facebook.com'; end
    end
  end
end

