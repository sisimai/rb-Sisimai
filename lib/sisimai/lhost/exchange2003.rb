module Sisimai::Lhost
  # Sisimai::Lhost::Exchange2003 parses a bounce email which created by Microsoft Exchange Server 2003.
  # Methods in the module are called from only Sisimai::Message.
  module Exchange2003
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = {
        message: ['Your message'],
        error:   ['did not reach the following recipient(s):'],
      }.freeze
      ErrorCodes = {
        'onhold' => [
          '000B099C', # Host Unknown, Message exceeds size limit, ...
          '000B09AA', # Unable to relay for, Message exceeds size limit,...
          '000B09B6', # Error messages by remote MTA
        ],
        'userunknown' => [
          '000C05A6', # Unknown Recipient,
        ],
        'systemerror' => [
          '00010256', # Too many recipients.
          '000D06B5', # No proxy for recipient (non-smtp mail?)
        ],
        'networkerror' => [
          '00120270', # Too Many Hops
        ],
        'contenterror' => [
          '00050311', # Conversion to Internet format failed
          '000502CC', # Conversion to Internet format failed
        ],
        'securityerror' => [
          '000B0981', # 502 Server does not support AUTH
        ],
        'filtered' => [
          '000C0595', # Ambiguous Recipient
        ],
      }.freeze

      # Parse bounce messages from Microsoft Exchange Server 2003
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        match = 0
        tryto = []

        # X-MS-TNEF-Correlator: <00000000000000000000000000000000000000@example.com>
        # X-Mailer: Internet Mail Service (5.5.1960.3)
        # X-MS-Embedded-Report:
        match += 1 if mhead['x-ms-embedded-report']
        catch :EXCHANGE_OR_NOT do
          while true
            throw :EXCHANGE_OR_NOT if match > 0

            if mhead['x-mailer']
              # X-Mailer:  Microsoft Exchange Server Internet Mail Connector Version 4.0.994.63
              # X-Mailer: Internet Mail Service (5.5.2232.9)
              tryto = ['Internet Mail Service (', 'Microsoft Exchange Server Internet Mail Connector']
              match += 1 if mhead['x-mailer'].start_with?(tryto[0], tryto[1])
              throw :EXCHANGE_OR_NOT if match > 0
            end

            if mhead['x-mimeole']
              # X-MimeOLE: Produced By Microsoft Exchange V6.5
              match += 1 if mhead['x-mimeole'].start_with?('Produced By Microsoft Exchange')
              throw :EXCHANGE_OR_NOT if match > 0
            end

            throw :EXCHANGE_OR_NOT if mhead['received'].empty?
            mhead['received'].each do |e|
              # Received: by ***.**.** with Internet Mail Service (5.5.2657.72)
              next unless e.include?(' with Internet Mail Service (')
              match += 1
              throw :EXCHANGE_OR_NOT
            end
            break
          end
        end
        return nil unless match > 0

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        statuspart = false  # (Boolean) Flag, true = have got delivery status part.
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'to'      => '',  # The value of "To"
          'date'    => '',  # The value of "Date"
          'subject' => '',  # The value of "Subject"
        }
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
          next if statuspart

          if connvalues == connheader.keys.size
            # did not reach the following recipient(s):
            #
            # kijitora@example.co.jp on Thu, 29 Apr 2007 16:51:51 -0500
            #     The recipient name is not recognized
            #     The MTS-ID of the original message is: c=jp;a= ;p=neko
            # ;l=EXCHANGE000000000000000000
            #     MSEXCH:IMS:KIJITORA CAT:EXAMPLE:EXCHANGE 0 (000C05A6) Unknown Recipient
            # mikeneko@example.co.jp on Thu, 29 Apr 2007 16:51:51 -0500
            #     The recipient name is not recognized
            #     The MTS-ID of the original message is: c=jp;a= ;p=neko
            # ;l=EXCHANGE000000000000000000
            #     MSEXCH:IMS:KIJITORA CAT:EXAMPLE:EXCHANGE 0 (000C05A6) Unknown Recipient
            v = dscontents[-1]

            if cv = e.match(/\A[ \t]*([^ ]+[@][^ ]+) on[ \t]*.*\z/) ||
                    e.match(/\A[ \t]*.+(?:SMTP|smtp)=([^ ]+[@][^ ]+) on[ \t]*.*\z/)
              # kijitora@example.co.jp on Thu, 29 Apr 2007 16:51:51 -0500
              #   kijitora@example.com on 4/29/99 9:19:59 AM
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['msexch'] = false
              recipients += 1

            elsif cv = e.match(/\A[ \t]+(MSEXCH:.+)\z/)
              #     MSEXCH:IMS:KIJITORA CAT:EXAMPLE:EXCHANGE 0 (000C05A6) Unknown Recipient
              v['diagnosis'] ||= ''
              v['diagnosis'] << cv[1]
            else
              next if v['msexch']
              if v['diagnosis'].to_s.start_with?('MSEXCH:')
                # Continued from MEEXCH in the previous line
                v['msexch'] = true
                v['diagnosis'] << ' ' << e
                statuspart = true
              else
                # Error message in the body part
                v['alterrors'] ||= ''
                v['alterrors'] << ' ' << e
              end
            end
          else
            # Your message
            #
            #  To:      shironeko@example.jp
            #  Subject: ...
            #  Sent:    Thu, 29 Apr 2010 18:14:35 +0000
            #
            if cv = e.match(/\A[ \t]+To:[ \t]+(.+)\z/)
              #  To:      shironeko@example.jp
              next unless connheader['to'].empty?
              connheader['to'] = cv[1]
              connvalues += 1

            elsif cv = e.match(/\A[ \t]+Subject:[ \t]+(.+)\z/)
              #  Subject: ...
              next unless connheader['subject'].empty?
              connheader['subject'] = cv[1]
              connvalues += 1

            elsif cv = e.match(%r|\A[ \t]+Sent:[ \t]+([A-Z][a-z]{2},.+[-+]\d{4})\z|) ||
                       e.match(%r|\A[ \t]+Sent:[ \t]+(\d+[/]\d+[/]\d+[ \t]+\d+:\d+:\d+[ \t].+)|)
              #  Sent:    Thu, 29 Apr 2010 18:14:35 +0000
              #  Sent:    4/29/99 9:19:59 AM
              next unless connheader['date'].empty?
              connheader['date'] = cv[1]
              connvalues += 1
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e.delete('msexch')
          if cv = e['diagnosis'].match(/\AMSEXCH:.+[ \t]*[(]([0-9A-F]{8})[)][ \t]*(.*)\z/)
            #     MSEXCH:IMS:KIJITORA CAT:EXAMPLE:EXCHANGE 0 (000C05A6) Unknown Recipient
            capturedcode = cv[1]
            errormessage = cv[2]

            ErrorCodes.each_key do |r|
              # Find captured code from the error code table
              next unless ErrorCodes[r].index(capturedcode)
              e['reason'] = r
              e['status'] = Sisimai::SMTP::Status.code(r.to_s) || ''
              break
            end
            e['diagnosis'] = errormessage
          end

          unless e['reason']
            # Could not detect the reason from the value of "diagnosis".
            next unless e['alterrors']
            next if e['alterrors'].empty?

            # Copy alternative error message
            e['diagnosis'] = e['alterrors'] + ' ' + e['diagnosis']
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e.delete('alterrors')
          end
        end

        if emailsteak[1].empty?
          # When original message does not included in the bounce message
          emailsteak[1] << ('From: ' << connheader['to'] << "\n")
          emailsteak[1] << ('Date: ' << connheader['date'] << "\n")
          emailsteak[1] << ('Subject: ' << connheader['subject'] << "\n")
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Microsoft Exchange Server 2003'; end
    end
  end
end

