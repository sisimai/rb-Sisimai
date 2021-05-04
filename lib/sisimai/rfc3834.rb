module Sisimai
  # Sisimai::RFC3834 - RFC3834 auto reply message detector
  module RFC3834
    class << self
      # http://tools.ietf.org/html/rfc3834
      MarkingsOf = { :boundary => %r/\A__SISIMAI_PSEUDO_BOUNDARY__\z/ }
      AutoReply1 = {
        # http://www.iana.org/assignments/auto-submitted-keywords/auto-submitted-keywords.xhtml
        'auto-submitted' => %r/\Aauto-(?:generated|replied|notified)/,
        # https://msdn.microsoft.com/en-us/library/ee219609(v=exchg.80).aspx
        'x-auto-response-suppress' => %r/(?:oof|autoreply)/,
        'x-apple-action' => %r/\Avacation\z/,
        'precedence' => %r/\Aauto_reply\z/,
        'subject' => %r/\A(?>
             auto:
            |auto[ ]response:
            |automatic[ ]reply:
            |out[ ]of[ ](?:the[ ])*office:
          )
        /x,
      }.freeze
      Excludings = {
        'subject' => %r/(?:
             security[ ]information[ ]for  # sudo
            |mail[ ]failure[ ][-]          # Exim
            )
        /x,
        'from' => %r/(?:root|postmaster|mailer-daemon)[@]/,
        'to'   => %r/root[@]/,
      }.freeze
      SubjectSet = %r{\A(?>
         (?:.+?)?Re:
        |Auto(?:[ ]Response):
        |Automatic[ ]reply:
        |Out[ ]of[ ]Office:
        )
        [ ]*(.+)\z
      }xi.freeze

      # Detect auto reply message as RFC3834
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        leave = 0
        match = 0

        # DETECT_EXCLUSION_MESSAGE
        Excludings.each_key do |e|
          # Exclude message from root@
          next unless mhead[e]
          next unless mhead[e]
          next unless mhead[e].downcase =~ Excludings[e]
          leave = 1
          break
        end
        return nil if leave > 0

        # DETECT_AUTO_REPLY_MESSAGE
        AutoReply1.each_key do |e|
          # RFC3834 Auto-Submitted and other headers
          next unless mhead[e]
          next unless mhead[e]
          next unless mhead[e].downcase =~ AutoReply1[e]
          match += 1
          break
        end
        return nil if match < 1

        require 'sisimai/lhost'
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        bodyslices = mbody.scrub('?').split("\n")
        rfc822part = '' # (String) message/rfc822-headers part
        recipients = 0  # (Integer) The number of 'Final-Recipient' header
        maxmsgline = 5  # (Integer) Max message length(lines)
        haveloaded = 0  # (Integer) The number of lines loaded from message body
        blanklines = 0  # (Integer) Counter for countinuous blank lines
        countuntil = 1  # (Integer) Maximum value of blank lines in the body part
        v = dscontents[-1]

        # RECIPIENT_ADDRESS
        %w[from return-path].each do |e|
          # Try to get the address of the recipient
          next unless mhead[e]
          next unless mhead[e]
          v['recipient'] = mhead[e]
          break
        end

        if v['recipient']
          # Clean-up the recipient address
          v['recipient'] = Sisimai::Address.s3s4(v['recipient'])
          recipients += 1
        end
        return nil unless recipients > 0

        if mhead['content-type']
          # Get the boundary string and set regular expression for matching with the boundary string.
          b0 = Sisimai::RFC2045.boundary(mhead['content-type'], 0) || ''
          MarkingsOf[:boundary] = %r/\A\Q#{b0}\E\z/ unless b0.empty?
        end

        # BODY_PARSER: Get vacation message
        while e = bodyslices.shift do
          # Read the first 5 lines except a blank line
          countuntil += 1 if e =~ MarkingsOf[:boundary]

          if e.empty?
            # Check a blank line
            blanklines += 1
            break if blanklines > countuntil
            next
          end
          next unless e.include?(' ')
          next if e.start_with?('Content-Type')
          next if e.start_with?('Content-Transfer')

          v['diagnosis'] ||= ''
          v['diagnosis']  << e + ' '
          haveloaded += 1
          break if haveloaded >= maxmsgline
        end
        v['diagnosis'] ||= mhead['subject']
        v['diagnosis'] = Sisimai::String.sweep(v['diagnosis'])
        v['reason']    = 'vacation'
        v['date']      = mhead['date']
        v['status']    = ''

        if cv = mhead['subject'].match(SubjectSet)
          # Get the Subject header from the original message
          rfc822part = 'Subject: ' << cv[1] + "\n"
        end
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end
      def description; 'Detector for auto replied message'; end
    end
  end
end
