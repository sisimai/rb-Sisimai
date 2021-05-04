module Sisimai::Lhost
  # Sisimai::Lhost::V5sendmail parses a bounce email which created by Sendmail version 5. Methods in
  # the module are called from only Sisimai::Message.
  module V5sendmail
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r/^[ ]+-----[ ](?:Unsent[ ]message[ ]follows|No[ ]message[ ]was[ ]collected)[ ]-----/.freeze
      StartingOf = { message: ['----- Transcript of session follows -----'] }
      MarkingsOf = {
        # Error text regular expressions which defined in src/savemail.c
        #   savemail.c:485| (void) fflush(stdout);
        #   savemail.c:486| p = queuename(e->e_parent, 'x');
        #   savemail.c:487| if ((xfile = fopen(p, "r")) == NULL)
        #   savemail.c:488| {
        #   savemail.c:489|   syserr("Cannot open %s", p);
        #   savemail.c:490|   fprintf(fp, "  ----- Transcript of session is unavailable -----\n");
        #   savemail.c:491| }
        #   savemail.c:492| else
        #   savemail.c:493| {
        #   savemail.c:494|   fprintf(fp, "   ----- Transcript of session follows -----\n");
        #   savemail.c:495|   if (e->e_xfp != NULL)
        #   savemail.c:496|       (void) fflush(e->e_xfp);
        #   savemail.c:497|   while (fgets(buf, sizeof buf, xfile) != NULL)
        #   savemail.c:498|       putline(buf, fp, m);
        #   savemail.c:499|   (void) fclose(xfile);
        error:   %r/\A[.]+ while talking to .+[:]\z/,
      }.freeze

      # Parse bounce messages from Sendmail version 5
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # :from => %r/\AMail Delivery Subsystem/,
        return nil unless mhead['subject'] =~ /\AReturned mail: [A-Z]/

        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        return nil if emailsteak[1].empty?

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        responding = []     # (Array) Responses from remote server
        commandset = []     # (Array) SMTP command which is sent to remote server
        anotherset = {}     # (Hash) Another error information
        errorindex = -1     # (Integer)
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.include?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          #    ----- Transcript of session follows -----
          # While talking to smtp.example.com:
          # >>> RCPT To:<kijitora@example.org>
          # <<< 550 <kijitora@example.org>, User Unknown
          # 550 <kijitora@example.org>... User unknown
          # 421 example.org (smtp)... Deferred: Connection timed out during user open with example.org
          v = dscontents[-1]

          if cv = e.match(/\A\d{3}[ ]+[<]([^ ]+[@][^ ]+)[>][.]{3}[ ]*(.+)\z/)
            # 550 <kijitora@example.org>... User unknown
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            v['diagnosis'] = cv[2]

            # Concatenate the response of the server and error message
            v['diagnosis'] << ': ' << responding[recipients] if responding[recipients]
            recipients += 1

          elsif cv = e.match(/\A[>]{3}[ ]*([A-Z]{4})[ ]*/)
            # >>> RCPT To:<kijitora@example.org>
            commandset[recipients] = cv[1]

          elsif cv = e.match(/\A[<]{3}[ ]+(.+)\z/)
            # <<< Response
            # <<< 501 <shironeko@example.co.jp>... no access from mail server [192.0.2.55] which is an open relay.
            # <<< 550 Requested User Mailbox not found. No such user here.
            responding[recipients] = cv[1]
          else
            # Detect SMTP session error or connection error
            next if v['sessionerr']

            if e =~ MarkingsOf[:error]
              # ----- Transcript of session follows -----
              # ... while talking to mta.example.org.:
              v['sessionerr'] = true
              next
            end

            if cv = e.match(/\A\d{3}[ ]+.+[.]{3}[ \t]*(.+)\z/)
              # 421 example.org (smtp)... Deferred: Connection timed out during user open with example.org
              anotherset['diagnosis'] = cv[1]
            end
          end
        end

        if recipients == 0 && cv = emailsteak[1].match(/^To:[ ]*(.+)$/)
          # Get the recipient address from "To:" header at the original message
          dscontents[0]['recipient'] = Sisimai::Address.s3s4(cv[1])
          recipients = 1
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          errorindex += 1
          e['command'] = commandset[errorindex] || ''
          e['diagnosis'] ||= if anotherset['diagnosis'].to_s.size > 0
                               # Copy alternative error message
                               anotherset['diagnosis']
                             else
                               # Set server response as a error message
                               responding[errorindex]
                             end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          unless e['recipient'] =~ /\A[^ ]+[@][^ ]+\z/
            # @example.jp, no local part
            if cv = e['diagnosis'].match(/[<]([^ ]+[@][^ ]+)[>]/)
              # Get email address from the value of Diagnostic-Code header
              e['recipient'] = cv[1]
            end
          end
          e.delete('sessionerr')
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Sendmail version 5'; end
    end
  end
end

