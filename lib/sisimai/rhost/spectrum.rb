module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data object as an argument
    # of get() method when the value of "destination" of the object is "charter.net".  This class is
    # called only Sisimai::Data class.
    module Spectrum
      class << self
        ErrorCodes = {
          # https://www.spectrumbusiness.net/support/internet/understanding-email-error-codes
          #   Error codes are placed in one of two categories: incoming or outgoing.
          #   1. If you are trying to send an email to a Charter email address from a non-Charter email
          #      address (such as Gmail, Yahoo, Hotmail, etc.), you may receive an error that begins
          #      with AUP#I, followed by four numbers.
          #
          #   2. If you are trying to send an email from a Charter email address to an outgoing recipient,
          #      you may get an error code beginning with AUP#O, also followed by four numbers.
          #
          1000 => 'blocked',         # Your IP address has been blocked due to suspicious activity. 
          1010 => 'rejected',        # This email account has been blocked from sending emails due to suspicious activity.
          1090 => 'systemerror',     # The email you're trying to send can't be processed. Try sending again at a later time.
          1260 => 'networkerror',    # Spectrum doesn't process IPV6 addresses. Connect with an IPv4 address and try again.
          1500 => 'rejected',        # Your email was rejected for attempting to send as a different email address than you signed in under.
          1520 => 'rejected',        # Your email was rejected for attempting to send as a different email address than a domain that we host.
          1530 => 'mesgtoobig',      # Your email was rejected because it's larger than the maximum size of 20MB.
          1540 => 'toomanyconn',     # Your emails were deferred for attempting to send too many in a single session.
          1550 => 'toomanyconn',     # Your email was rejected for having too many recipients in one message.
          1560 => 'policyviolation', # Your email was rejected for having too many invalid recipients.
        }.freeze
        CodeRanges = [
          [1020, 1080, 'rejected'],        # This email account has limited access to send emails based on suspicious activity.
          [1100, 1150, 'blocked'],         # The IP address you're trying to connect from has an issue with the Domain Name System.
          [1160, 1190, 'policyviolation'], # The email you tried to send goes against your domain's security policies.
          [1200, 1210, 'blocked'],         # The IP address you're trying to send from has been flagged by Cloudmark CSI as potential spam.
          [1220, 1250, 'blokced'],         # Your IP address has been blacklisted by Spamhaus.
          [1300, 1340, 'toomanyconn'],     # Spectrum limits the number of concurrent connections from a sender
          [1350, 1490, 'toomanyconn'],     # Spectrum limits emails by the number of messages sent, amount of recipients,...
        ].freeze

        # Detect bounce reason from https://www.spectrum.com/
        # @param    [Sisimai::Data] argvs   Parsed email object
        # @return   [String, Nil]           The bounce reason at Spectrum
        # @since v4.25.8
        def get(argvs)
          statusmesg = argvs['diagnosticcode']
          codenumber = 0

          if cv = statusmesg.match(/AUP#[-A-Za-z]*(\d{4})/)
            # Capture the numeric part of the error code
            codenumber = cv[1].to_i
          end
          reasontext = ErrorCodes[codenumber] || ''

          if reasontext.empty?
            # The error code was not found in ErrorCodes
            CodeRanges.each do |e|
              # Check the code range
              next if codenumber < e[0]
              next if codenumber > e[1]
              reasontext = e[2]
              break
            end
          end

          return reasontext
        end

      end
    end
  end
end

