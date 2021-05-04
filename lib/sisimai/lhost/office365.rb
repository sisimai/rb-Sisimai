module Sisimai::Lhost
  # Sisimai::Lhost::Office365 parses a bounce email which created by Microsoft Office 365. Methods in
  # the module are called from only Sisimai::Message.
  module Office365
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = {
        error:  ['Diagnostic information for administrators:'],
        eoerr:  ['Original message headers:'],
      }.freeze
      MarkingsOf = {
        eoe:     %r{\A(?:
           Original[ ][Mm]essage[ ][Hh]eaders:?
          |Message[ ]Hops
          |Cabe.+alhos[ ]originais[ ]da[ ]mensagem:
          |Oorspronkelijke[ ]berichtkoppen:
          )
        }x,
        rfc3464: %r|\AContent-Type:[ ]message/delivery-status|,
        lhost:   %r{\A(?:
           Generating[ ]server
          |Bronserver
          |Servidor[ ]de[ ]origem
          ):[ ](.+)\z
        }x,
        error:   %r{\A(?:
           Diagnostic[ ]information[ ]for[ ]administrators:
          |Error[ ]Details
          |Diagnostische[ ]gegevens[ ]voor[ ]beheerders:
          |Informa.+es[ ]de[ ]diagn.+stico[ ]para[ ]administradores:
          )
        }x,
        message: %r{\A(?:
           Delivery[ ]has[ ]failed[ ]to[ ]these[ ]recipients[ ]or[ ]groups:
          |Original[ ]Message[ ]Details
          |.+[ ]rejected[ ]your[ ]message[ ]to[ ]the[ ]following[ ]e[-]?mail[ ]addresses:
          |Falha[ ]na[ ]entrega[ ]a[ ]estes[ ]destinat.+rios[ ]ou[ ]grupos:
          |Uw[ ]bericht[ ]kan[ ]niet[ ]worden[ ]bezorgd[ ]bij[ ]de[ ]volgende[ ]geadresseerden[ ]of[ ]groepen:
          )
        }x,
      }.freeze
      Headers365 = %w[
        x-ms-exchange-message-is-ndr
        x-microsoft-antispam-prvs
        x-exchange-antispam-report-test
        x-exchange-antispam-report-cfa-test
        x-ms-exchange-crosstenant-originalarrivaltime
        x-ms-exchange-crosstenant-fromentityheader
        x-ms-exchange-transport-crosstenantheadersstamped
      ]
      StatusList = {
        # https://support.office.com/en-us/article/Email-non-delivery-reports-in-Office-365-51daa6b9-2e35-49c4-a0c9-df85bf8533c3
        %r/\A4[.]4[.]7\z/        => 'expired',
        %r/\A4[.]4[.]312\z/      => 'networkerror',
        %r/\A4[.]4[.]316\z/      => 'expired',
        %r/\A4[.]7[.]26\z/       => 'securityerror',
        %r/\A4[.]7[.][56]\d\d\z/ => 'blocked',
        %r/\A4[.]7[.]8[5-9]\d\z/ => 'blocked',
        %r/\A5[.]0[.]350\z/      => 'contenterror',
        %r/\A5[.]1[.]10\z/       => 'userunknown',
        %r/\A5[.]4[.]1\z/        => 'norelaying',
        %r/\A5[.]4[.]312\z/      => 'networkerror',
        %r/\A5[.]4[.]316\z/      => 'expired',
        %r/\A5[.]4[.]6\z/        => 'networkerror',
        %r/\A5[.]6[.]11\z/       => 'contenterror',
        %r/\A5[.]7[.]1\z/        => 'rejected',
        %r/\A5[.]7[.]1[23]\z/    => 'rejected',
        %r/\A5[.]7[.]124\z/      => 'rejected',
        %r/\A5[.]7[.]13[3-6]\z/  => 'rejected',
        %r/\A5[.]7[.]23\z/       => 'blocked',
        %r/\A5[.]7[.]25\z/       => 'networkerror',
        %r/\A5[.]7[.]50[1-3]\z/  => 'spamdetected',
        %r/\A5[.]7[.]50[4-5]\z/  => 'filtered',
        %r/\A5[.]7[.]50[6-7]\z/  => 'blocked',
        %r/\A5[.]7[.]508\z/      => 'toomanyconn',
        %r/\A5[.]7[.]509\z/      => 'securityerror',
        %r/\A5[.]7[.]510\z/      => 'notaccept',
        %r/\A5[.]7[.]511\z/      => 'rejected',
        %r/\A5[.]7[.]512\z/      => 'securityerror',
        %r/\A5[.]7[.]57\z/       => 'securityerror',
        %r/\A5[.]7[.]60[6-9]\z/  => 'blocked',
        %r/\A5[.]7[.]6[1-4]\d\z/ => 'blocked',
        %r/\A5[.]7[.]7[0-4]\d\z/ => 'toomanyconn',
      }.freeze
      ReCommands = {
        RCPT: %r/unknown recipient or mailbox unavailable ->.+[<]?.+[@].+[.][a-zA-Z]+[>]?/,
      }.freeze

      # Parse bounce messages from Microsoft Office 365
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # X-MS-Exchange-Message-Is-Ndr:
        # X-Microsoft-Antispam-PRVS: <....@...outlook.com>
        # X-Exchange-Antispam-Report-Test: UriScan:;
        # X-Exchange-Antispam-Report-CFA-Test:
        # X-MS-Exchange-CrossTenant-OriginalArrivalTime: 29 Apr 2015 23:34:45.6789 (JST)
        # X-MS-Exchange-CrossTenant-FromEntityHeader: Hosted
        # X-MS-Exchange-Transport-CrossTenantHeadersStamped: ...
        tryto  = %r/.+[.](?:outbound[.]protection|prod)[.]outlook[.]com\b/
        match  = 0
        match += 1 if mhead['subject'].include?('Undeliverable:')
        match += 1 if mhead['subject'].include?('Onbestelbaar:')
        match += 1 if mhead['subject'].include?('Não_entregue:')

        Headers365.each do |e|
          next if mhead[e].nil?
          next if mhead[e].empty?
          match += 1
        end
        match += 1 if mhead['received'].any? { |a| a =~ tryto }
        if mhead['message-id']
          # Message-ID: <00000000-0000-0000-0000-000000000000@*.*.prod.outlook.com>
          match += 1 if mhead['message-id'] =~ tryto
        end
        return nil if match < 2

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        connheader = {}
        endoferror = false  # (Boolean) Flag for the end of error messages
        htmlbegins = false  # (Boolean) Flag for HTML part
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

          # kijitora@example.com<mailto:kijitora@example.com>
          # The email address wasn't found at the destination domain. It might
          # be misspelled or it might not exist any longer. Try retyping the
          # address and resending the message.
          #
          # Original Message Details
          # Created Date:   4/29/2017 6:40:30 AM
          # Sender Address: neko@example.jp
          # Recipient Address:      kijitora@example.org
          # Subject:        Nyaan#
          v = dscontents[-1]

          if cv = e.match(/\A.+[@].+[<]mailto:(.+[@].+)[>]\z/) ||
                  e.match(/\ARecipient[ ]Address:[ ]+(.+)\z/)
            # kijitora@example.com<mailto:kijitora@example.com>
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            recipients += 1

          elsif cv = e.match(MarkingsOf[:lhost])
            # Generating server: FFFFFFFFFFFF.e0.prod.outlook.com
            connheader['lhost'] = cv[1].downcase
          else
            if endoferror
              # After "Original message headers:"
              next unless f = Sisimai::RFC1894.match(e)
              next unless o = Sisimai::RFC1894.field(e)
              next unless fieldtable[o[0]]

              if v['diagnosis']
                # Do not capture "Diagnostic-Code:" field because error message have already
                # been captured
                next if o[0] =~ /\A(?:diagnostic-code|final-recipient)\z/
                v[fieldtable[o[0]]] = o[2]

                next unless f == 1
                permessage[fieldtable[o[0]]] = o[2]
              else
                # Capture "Diagnostic-Code:" field because no error messages have been captured
                v[fieldtable[o[0]]] = o[2]
                permessage[fieldtable[o[0]]] = o[2]
              end
            else
              if e =~ MarkingsOf[:error]
                # Diagnostic information for administrators:
                v['diagnosis'] = e
              else
                # kijitora@example.com
                # Remote Server returned '550 5.1.10 RESOLVER.ADR.RecipientNotFound; Recipien=
                # t not found by SMTP address lookup'
                if v['diagnosis']
                  # The error message text have already captured
                  if e =~ MarkingsOf[:eoe]
                    # Original message headers:
                    endoferror = true
                    next
                  end
                  v['diagnosis'] << ' ' << e
                else
                  # The error message text has not been captured yet
                  endoferror = true if e =~ MarkingsOf[:rfc3464]
                end
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }

          e['status']  ||= ''
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''
          if e['status'].empty? || e['status'].end_with?('.0.0')
            # There is no value of Status header or the value is 5.0.0, 4.0.0
            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis']) || e['status']
          end

          ReCommands.each_key do |p|
            # Try to match with regular expressions defined in ReCommands
            next unless e['diagnosis'] =~ ReCommands[p]
            e['command'] = p.to_s
            break
          end
          next unless e['status']

          StatusList.each_key do |f|
            # Try to match with each key as a regular expression
            next unless e['status'] =~ f
            e['reason'] = StatusList[f]
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Microsoft Office 365: https://office.microsoft.com/'; end
    end
  end
end

