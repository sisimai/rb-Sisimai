module Sisimai::Lhost
  # Sisimai::Lhost::Exim parses a bounce email which created by Exim. Methods in the module are called
  # from only Sisimai::Message.
  module Exim
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      # deliver.c:6423|          if (bounce_return_body) fprintf(f,
      # deliver.c:6424|"------ This is a copy of the message, including all the headers. ------\n");
      # deliver.c:6425|          else fprintf(f,
      # deliver.c:6426|"------ This is a copy of the message's headers. ------\n");
      ReBackbone = %r{^(?:
         [-]+[ ]This[ ]is[ ]a[ ]copy[ ]of[ ](?:the|your)[ ]message,[ ]including[ ]all[ ]the[ ]headers[.][ ][-]+
        |Content-Type:[ ]*message/rfc822\n(?:[\s\t]+.*?\n\n)?
        )
      }x.freeze
      StartingOf = { deliverystatus: ['Content-type: message/delivery-status'] }.freeze
      MarkingsOf = {
        # Error text regular expressions which defined in exim/src/deliver.c
        #
        # deliver.c:6292| fprintf(f,
        # deliver.c:6293|"This message was created automatically by mail delivery software.\n");
        # deliver.c:6294|        if (to_sender)
        # deliver.c:6295|          {
        # deliver.c:6296|          fprintf(f,
        # deliver.c:6297|"\nA message that you sent could not be delivered to one or more of its\n"
        # deliver.c:6298|"recipients. This is a permanent error. The following address(es) failed:\n");
        # deliver.c:6299|          }
        # deliver.c:6300|        else
        # deliver.c:6301|          {
        # deliver.c:6302|          fprintf(f,
        # deliver.c:6303|"\nA message sent by\n\n  <%s>\n\n"
        # deliver.c:6304|"could not be delivered to one or more of its recipients. The following\n"
        # deliver.c:6305|"address(es) failed:\n", sender_address);
        # deliver.c:6306|          }
        alias:   %r/\A([ ]+an undisclosed address)\z/,
        frozen:  %r/\AMessage [^ ]+ (?:has been frozen|was frozen on arrival)/,
        message: %r{\A(?>
           This[ ]message[ ]was[ ]created[ ]automatically[ ]by[ ]mail[ ]delivery[ ]software[.]
          |A[ ]message[ ]that[ ]you[ ]sent[ ]was[ ]rejected[ ]by[ ]the[ ]local[ ]scanning[ ]code
          |A[ ]message[ ]that[ ]you[ ]sent[ ]contained[ ]one[ ]or[ ]more[ ]recipient[ ]addresses[ ]
          |A[ ]message[ ]that[ ]you[ ]sent[ ]could[ ]not[ ]be[ ]delivered[ ]to[ ]all[ ]of[ ]its[ ]recipients
          |Message[ ][^ ]+[ ](?:has[ ]been[ ]frozen|was[ ]frozen[ ]on[ ]arrival)
          |The[ ][^ ]+[ ]router[ ]encountered[ ]the[ ]following[ ]error[(]s[)]:
          )
         }x,
      }.freeze

      ReCommands = [
        # transports/smtp.c:564|  *message = US string_sprintf("SMTP error from remote mail server after %s%s: "
        # transports/smtp.c:837|  string_sprintf("SMTP error from remote mail server after RCPT TO:<%s>: "
        %r/SMTP error from remote (?:mail server|mailer) after ([A-Za-z]{4})/,
        %r/SMTP error from remote (?:mail server|mailer) after end of ([A-Za-z]{4})/,
        %r/LMTP error after ([A-Za-z]{4})/,
        %r/LMTP error after end of ([A-Za-z]{4})/,
      ].freeze
      MessagesOf = {
        # find exim/ -type f -exec grep 'message = US' {} /dev/null \;
        # route.c:1158|  DEBUG(D_uid) debug_printf("getpwnam() returned NULL (user not found)\n");
        'userunknown' => ['user not found'],
        # transports/smtp.c:3524|  addr->message = US"all host address lookups failed permanently";
        # routers/dnslookup.c:331|  addr->message = US"all relevant MX records point to non-existent hosts";
        # route.c:1826|  uschar *message = US"Unrouteable address";
        'hostunknown' => [
          'all host address lookups failed permanently',
          'all relevant MX records point to non-existent hosts',
          'Unrouteable address',
        ],
        # transports/appendfile.c:2567|  addr->user_message = US"mailbox is full";
        # transports/appendfile.c:3049|  addr->message = string_sprintf("mailbox is full "
        # transports/appendfile.c:3050|  "(quota exceeded while writing to file %s)", filename);
        'mailboxfull' => ['mailbox is full', 'error: quota exceed'],
        # routers/dnslookup.c:328|  addr->message = US"an MX or SRV record indicated no SMTP service";
        # transports/smtp.c:3502|  addr->message = US"no host found for existing SMTP connection";
        'notaccept' => [
          'an MX or SRV record indicated no SMTP service',
          'no host found for existing SMTP connection',
        ],
        # parser.c:666| *errorptr = string_sprintf("%s (expected word or \"<\")", *errorptr);
        # parser.c:701| if(bracket_count++ > 5) FAILED(US"angle-brackets nested too deep");
        # parser.c:738| FAILED(US"domain missing in source-routed address");
        # parser.c:747| : string_sprintf("malformed address: %.32s may not follow %.*s",
        'syntaxerror' => [
          'angle-brackets nested too deep',
          'expected word or "<"',
          'domain missing in source-routed address',
          'malformed address:',
        ],
        # deliver.c:5614|  addr->message = US"delivery to file forbidden";
        # deliver.c:5624|  addr->message = US"delivery to pipe forbidden";
        # transports/pipe.c:1156|  addr->user_message = US"local delivery failed";
        'systemerror' => [
          'delivery to file forbidden',
          'delivery to pipe forbidden',
          'local delivery failed',
          'LMTP error after ',
        ],
        # deliver.c:5425|  new->message = US"Too many \"Received\" headers - suspected mail loop";
        'contenterror' => ['Too many "Received" headers'],
      }.freeze

      # retry.c:902|  addr->message = (addr->message == NULL)? US"retry timeout exceeded" :
      # deliver.c:7475|  "No action is required on your part. Delivery attempts will continue for\n"
      # smtp.c:3508|  US"retry time not reached for any host after a long failure period" :
      # smtp.c:3508|  US"all hosts have been failing for a long time and were last tried "
      #                 "after this message arrived";
      # deliver.c:7459|  print_address_error(addr, f, US"Delay reason: ");
      # deliver.c:7586|  "Message %s has been frozen%s.\nThe sender is <%s>.\n", message_id,
      # receive.c:4021|  moan_tell_someone(freeze_tell, NULL, US"Message frozen on arrival",
      # receive.c:4022|  "Message %s was frozen on arrival by %s.\nThe sender is <%s>.\n",
      DelayedFor = [
        'retry timeout exceeded',
        'No action is required on your part',
        'retry time not reached for any host after a long failure period',
        'all hosts have been failing for a long time and were last tried',
        'Delay reason: ',
        'has been frozen',
        'was frozen on arrival by ',
      ].freeze

      # Parse bounce messages from Exim
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil if mhead['from'] =~ /[@].+[.]mail[.]ru[>]?/

        # Message-Id: <E1P1YNN-0003AD-Ga@example.org>
        # X-Failed-Recipients: kijitora@example.ed.jp
        match  = 0
        match += 1 if mhead['from'].start_with?('Mail Delivery System')
        match += 1 if mhead['message-id'].to_s =~ %r/\A[<]\w{7}[-]\w{6}[-]\w{2}[@]/
        match += 1 if mhead['subject'] =~ %r{(?:
           Mail[ ]delivery[ ]failed(:[ ]returning[ ]message[ ]to[ ]sender)?
          |Warning:[ ]message[ ][^ ]+[ ]delayed[ ]+
          |Delivery[ ]Status[ ]Notification
          |Mail[ ]failure
          |Message[ ]frozen
          |error[(]s[)][ ]in[ ]forwarding[ ]or[ ]filtering
          )
        }x
        return nil if match < 2

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        nextcursor = 0
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        localhost0 = ''     # (String) Local MTA
        boundary00 = ''     # (String) Boundary string
        v = nil

        if mhead['content-type']
          # Get the boundary string and set regular expression for matching with the boundary string.
          boundary00 = Sisimai::RFC2045.boundary(mhead['content-type']) || ''
        end

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            if e =~ MarkingsOf[:message]
              readcursor |= Indicators[:deliverystatus]
              next unless e =~ MarkingsOf[:frozen]
            end
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # This message was created automatically by mail delivery software.
          #
          # A message that you sent could not be delivered to one or more of its
          # recipients. This is a permanent error. The following address(es) failed:
          #
          #  kijitora@example.jp
          #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
          #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
          v = dscontents[-1]

          if cv = e.match(/\A[ \t]{2}([^ \t]+[@][^ \t]+[.]?[a-zA-Z]+)(:.+)?\z/) ||
                  e.match(/\A[ \t]{2}[^ \t]+[@][^ \t]+[.][a-zA-Z]+[ ]<(.+?[@].+?)>:.+\z/) ||
                  e.match(MarkingsOf[:alias])
            #   kijitora@example.jp
            #   sabineko@example.jp: forced freeze
            #   mikeneko@example.jp <nekochan@example.org>: ...
            #
            # deliver.c:4549|  printed = US"an undisclosed address";
            #   an undisclosed address
            #     (generated from kijitora@example.jp)
            r = cv[1]

            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            # v['recipient'] = cv[1]

            if cv = e.match(/\A[ \t]+[^ \t]+[@][^ \t]+[.][a-zA-Z]+[ ]<(.+?[@].+?)>:.+\z/)
              # parser.c:743| while (bracket_count-- > 0) if (*s++ != '>')
              # parser.c:744|   {
              # parser.c:745|   *errorptr = s[-1] == 0
              # parser.c:746|     ? US"'>' missing at end of address"
              # parser.c:747|     : string_sprintf("malformed address: %.32s may not follow %.*s",
              # parser.c:748|     s-1, (int)(s - US mailbox - 1), mailbox);
              # parser.c:749|   goto PARSE_FAILED;
              # parser.c:750|   }
              r = cv[1]
              v['diagnosis'] = e
            end
            v['recipient'] = r
            recipients += 1

          elsif cv = e.match(/\A[ ]+[(]generated[ ]from[ ](.+)[)]\z/) ||
                     e.match(/\A[ ]+generated[ ]by[ ]([^ \t]+[@][^ \t]+)/)
            #     (generated from kijitora@example.jp)
            #  pipe to |/bin/echo "Some pipe output"
            #    generated by userx@myhost.test.ex
            v['alias'] = cv[1]
          else
            next if e.empty?

            if e =~ MarkingsOf[:frozen]
              # Message *** has been frozen by the system filter.
              # Message *** was frozen on arrival by ACL.
              v['alterrors'] ||= ''
              v['alterrors'] <<  e + ' '
            else
              if !boundary00.empty?
                # --NNNNNNNNNN-eximdsn-MMMMMMMMMM
                # Content-type: message/delivery-status
                # ...
                if Sisimai::RFC1894.match(e)
                  # "e" matched with any field defined in RFC3464
                  next unless o = Sisimai::RFC1894.field(e)

                  if o[-1] == 'addr'
                    # Final-Recipient: rfc822; kijitora@example.jp
                    # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                    next unless o[0] == 'final-recipient'
                    v['spec'] ||= o[2].include?('@') ? 'SMTP' : 'X-UNIX'

                  elsif o[-1] == 'code'
                    # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                    v['spec'] = o[1]
                    v['diagnosis'] = o[2]

                  else
                    # Other DSN fields defined in RFC3464
                    next unless fieldtable[o[0]]
                    v[fieldtable[o[0]]] = o[2]
                  end
                else
                  # Error message ?
                  next if nextcursor == 1

                  # Content-type: message/delivery-status
                  nextcursor = 1 if e.start_with?(StartingOf[:deliverystatus][0])
                  v['alterrors'] ||= ''
                  if e.start_with?("\s", "\t")
                    e.sub!(/\A[\s\t]+/, '')
                    v['alterrors'] << e + ' ' unless v['alterrors'].include?(e)
                  end
                end
              else
                if dscontents.size == recipients
                  # Error message
                  next if e.empty?
                  v['diagnosis'] ||= ''
                  v['diagnosis'] << e + '  '
                else
                  # Error message when email address above does not include '@' and domain part.
                  if e =~ %r<\A[ ]+pipe[ ]to[ ][|]/[^ ]+>
                    # pipe to |/path/to/prog ...
                    #   generated by kijitora@example.com
                    v['diagnosis'] = e
                  else
                    next unless e.start_with?('    ')
                    v['alterrors'] ||= ''
                    v['alterrors'] << e + ' '
                  end
                end
              end
            end
          end
        end

        if recipients > 0
          # Check "an undisclosed address", "unroutable address"
          dscontents.each do |q|
            # Replace the recipient address with the value of "alias"
            next unless q['alias']
            next if q['alias'].empty?
            if q['recipient'].empty? || q['recipient'].include?('@') == false
              # The value of "recipient" is empty or does not include "@"
              q['recipient'] = q['alias']
            end
          end
        else
          # Fallback for getting recipient addresses
          if mhead['x-failed-recipients']
            # X-Failed-Recipients: kijitora@example.jp
            rcptinhead = mhead['x-failed-recipients'].split(',')
            rcptinhead.each do |a|
              # Remove space characters
              a.lstrip!
              a.rstrip!
            end
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

          unless e['diagnosis']
            # Empty Diagnostic-Code: or error message
            unless boundary00.empty?
              # --NNNNNNNNNN-eximdsn-MMMMMMMMMM
              # Content-type: message/delivery-status
              #
              # Reporting-MTA: dns; the.local.host.name
              #
              # Action: failed
              # Final-Recipient: rfc822;/a/b/c
              # Status: 5.0.0
              #
              # Action: failed
              # Final-Recipient: rfc822;|/p/q/r
              # Status: 5.0.0
              e['diagnosis'] = dscontents[0]['diagnosis'] || ''
              e['spec']    ||= dscontents[0]['spec']

              unless dscontents[0]['alterrors'].to_s.empty?
                # The value of "alterrors" is also copied
                e['alterrors'] = dscontents[0]['alterrors']
              end
            end
          end

          unless e['alterrors'].to_s.empty?
            # Copy alternative error message
            if e['diagnosis'].nil? || e['diagnosis'].empty?
              e['diagnosis'] = e['alterrors']
            end

            if e['diagnosis'].start_with?('-') || e['diagnosis'].end_with?('__')
              # Override the value of diagnostic code message
              e['diagnosis'] = e['alterrors'] unless e['alterrors'].empty?
            else
              # Check the both value and try to match
              if e['diagnosis'].size < e['alterrors'].size
                # Override the value of diagnostic code message because the value of alterrors includes
                # the value of diagnosis.
                e['diagnosis'] = e['alterrors'] if e['alterrors'].downcase.include?(e['diagnosis'].downcase)
              end
            end
            e.delete('alterrors')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''
          e['diagnosis'].sub!(/\b__.+\z/, '')

          unless e['rhost']
            # Get the remote host name
            # host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
            if cv = e['diagnosis'].match(/host[ \t]+([^ \t]+)[ \t]\[.+\]:[ \t]/) then e['rhost'] = cv[1] end

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
              e['reason'] = 'onhold'
            else
              # Verify each regular expression of session errors
              MessagesOf.each_key do |r|
                # Check each regular expression
                next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
                e['reason'] = r
                break
              end

              unless e['reason']
                # The reason "expired"
                e['reason'] = 'expired' if DelayedFor.any? { |a| e['diagnosis'].include?(a) }
              end
            end
          end

          # Prefer the value of smtp reply code in Diagnostic-Code:
          #   Action: failed
          #   Final-Recipient: rfc822;userx@test.ex
          #   Status: 5.0.0
          #   Remote-MTA: dns; 127.0.0.1
          #   Diagnostic-Code: smtp; 450 TEMPERROR: retry timeout exceeded
          #
          # The value of "Status:" indicates permanent error but the value of SMTP reply code in
          # Diagnostic-Code: field is "TEMPERROR"!!!!
          sv = Sisimai::SMTP::Status.find(e['diagnosis'])
          rv = Sisimai::SMTP::Reply.find(e['diagnosis'])
          s1 = 0  # First character of Status as integer
          r1 = 0  # First character of SMTP reply code as integer

          while true
            # "Status:" field did not exist in the bounce message
            break if sv
            break unless rv

            # Check SMTP reply code, Generate pseudo DSN code from SMTP reply code
            r1 = rv[0, 1].to_i
            if r1 == 4
              # Get the internal DSN(temporary error)
              sv = Sisimai::SMTP::Status.code(e['reason'], true)

            elsif r1 == 5
              # Get the internal DSN(permanent error)
              sv = Sisimai::SMTP::Status.code(e['reason'], false)
            end
            break
          end

          s1 = sv[0, 1].to_i if sv
          v1 = s1 + r1
          v1 << e['status'][0, 1].to_i if e['status']

          if v1 > 0
            # Status or SMTP reply code exists, Set pseudo DSN into the value of "status" accessor
            e['status'] = sv if r1 > 0
          else
            # Neither Status nor SMTP reply code exist
            sv = if %w[expired mailboxfull].include?(e['reason'])
                   # Set pseudo DSN (temporary error)
                   Sisimai::SMTP::Status.code(e['reason'], true)
                 else
                   # Set pseudo DSN (permanent error)
                   Sisimai::SMTP::Status.code(e['reason'], false)
                 end
          end
          e['status'] ||= sv.to_s
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Exim'; end
    end
  end
end

