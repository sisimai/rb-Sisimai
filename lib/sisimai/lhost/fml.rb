module Sisimai::Lhost
  # Sisimai::Lhost::FML parses a bounce email which created by fml. Methods in the module are called
  # from only Sisimai::Message.
  module FML
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Original[ ]mail[ ]as[ ]follows:|.freeze
      ErrorTitle = {
        'rejected' => %r{(?>
           (?:Ignored[ ])*NOT[ ]MEMBER[ ]article[ ]from[ ]
          |reject[ ]mail[ ](?:.+:|from)[ ],
          |Spam[ ]mail[ ]from[ ]a[ ]spammer[ ]is[ ]rejected
          |You[ ].+[ ]are[ ]not[ ]member
          )
        }x,
        'systemerror' => %r{(?:
           fml[ ]system[ ]error[ ]message
          |Loop[ ]Alert:[ ]
          |Loop[ ]Back[ ]Warning:[ ]
          |WARNING:[ ]UNIX[ ]FROM[ ]Loop
          )
        }x,
        'securityerror' => %r/Security Alert/,
      }.freeze
      ErrorTable = {
        'rejected' => %r{(?>
          (?:Ignored[ ])*NOT[ ]MEMBER[ ]article[ ]from[ ]
          |reject[ ](?:
             mail[ ]from[ ].+[@].+
            |since[ ].+[ ]header[ ]may[ ]cause[ ]mail[ ]loop
            |spammers:
            )
          |You[ ]are[ ]not[ ]a[ ]member[ ]of[ ]this[ ]mailing[ ]list
          )
        }x,
        'systemerror' => %r{(?:
           Duplicated[ ]Message-ID
          |fml[ ].+[ ]has[ ]detected[ ]a[ ]loop[ ]condition[ ]so[ ]that
          |Loop[ ]Back[ ]Warning:
          )
        }x,
        'securityerror' => %r/Security alert:/,
      }.freeze

      # Parse bounce messages from fml mailling list server/manager
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      # @since v4.22.3
      def inquire(mhead, mbody)
        return nil unless mhead['x-mlserver']
        return nil unless mhead['from'] =~ /.+[-]admin[@].+/
        return nil unless mhead['message-id'] =~ /\A[<]\d+[.]FML.+[@].+[>]\z/

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          next if e.empty?

          # Duplicated Message-ID in <2ndml@example.com>.
          # Original mail as follows:
          v = dscontents[-1]

          if cv = e.match(/[<]([^ ]+?[@][^ ]+?)[>][.]\z/)
            # Duplicated Message-ID in <2ndml@example.com>.
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            v['diagnosis'] = e
            recipients += 1
          else
            # If you know the general guide of this list, please send mail with
            # the mail body
            v['diagnosis'] ||= ''
            v['diagnosis'] << e
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          ErrorTable.each_key do |f|
            # Try to match with error messages defined in ErrorTable
            next unless e['diagnosis'] =~ ErrorTable[f]
            e['reason'] = f
            break
          end

          unless e['reason']
            # Error messages in the message body did not matched
            ErrorTitle.each_key do |f|
              # Try to match with the Subject string
              next unless mhead['subject'] =~ ErrorTitle[f]
              e['reason'] = f
              break
            end
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'fml mailing list server/manager'; end
    end
  end
end

