module Sisimai
  module Reason
    # Sisimai::Reason::Rejected checks the bounce reason is "rejected" or not. This class is called
    # only Sisimai::Reason class.
    #
    # This is the error that a connection to destination server was rejected by a sender's email
    # address (envelope from). Sisimai set "rejected" to the reason of email bounce if the value of
    # Status: field in a bounce email is "5.1.8" or the connection has been rejected due to the
    # argument of SMTP MAIL command.
    #
    #   <kijitora@example.org>:
    #   Connected to 192.0.2.225 but sender was rejected.
    #   Remote host said: 550 5.7.1 <root@nijo.example.jp>... Access denied
    module Rejected
      class << self
        IsNot = [
          '5.1.0 address rejected',
          'recipient address rejected',
          'sender ip address rejected',
        ]
        Index = [
          'access denied (in reply to mail from command)',
          'access denied (sender blacklisted)',
          'address rejected',
          'administrative prohibition',
          'batv failed to verify',    # SoniWall
          'batv validation failure',  # SoniWall
          'backscatter protection detected an invalid or expired email address',  # MDaemon
          'bogus mail from',          # IMail - block empty sender
          'connections not accepted from servers without a valid sender domain',
          'denied [bouncedeny]',      # McAfee
          'denied by secumail valid-address-filter',
          'delivery not authorized, message refused',
          'does not exist e2110',
          'domain of sender address ',
          'emetteur invalide',
          'empty envelope senders not allowed',
          'envelope blocked – ',
          'error: no third-party dsns',   # SpamWall - block empty sender
          'from: domain is invalid. please provide a valid from:',
          'fully qualified email address required',   # McAfee
          'invalid domain, see <url:',
          'invalid sender',
          'is not a registered gateway user',
          'mail from not owned by user',
          'message rejected: email address is not verified',
          'mx records for ',
          'null sender is not allowed',
          'recipient addresses rejected : access denied',
          'recipient not accepted. (batv: no tag',
          'returned mail not accepted here',
          'rfc 1035 violation: recursive cname records for',
          'rule imposed mailbox access for',  # MailMarshal
          'sender address has been blacklisted',
          'sender email address rejected',
          'sender is spammer',
          'sender not pre-approved',
          'sender rejected',
          'sender domain is empty',
          'sender verify failed', # Exim callout
          'syntax error: empty email address',
          'the message has been rejected by batv defense',
          'this server does not accept mail from',
          'transaction failed unsigned dsn for',
          'unroutable sender address',
          'you are sending to/from an address that has been blacklisted',
        ]

        def text; return 'rejected'; end
        def description; return "Email rejected due to a sender's email address (envelope from)"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return false if IsNot.any? { |a| argv1.include?(a) }
          return true  if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Rejected by the envelope sender address or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is rejected
        #                                   false: is not rejected by the sender
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'rejected'
          tempreason = Sisimai::SMTP::Status.name(argvs['deliverystatus']) || 'undefined'
          return true if tempreason == 'rejected' # Delivery status code points "rejected".

          # Check the value of Diagnosic-Code: header with patterns
          diagnostic = argvs['diagnosticcode'].downcase
          commandtxt = argvs['smtpcommand']
          if commandtxt == 'MAIL'
            # The session was rejected at 'MAIL FROM' command
            return true if match(diagnostic)

          elsif commandtxt == 'DATA'
            # The session was rejected at 'DATA' command
            if tempreason != 'userunknown'
              # Except "userunknown"
              return true if match(diagnostic)
            end
          elsif %w[onhold undefined securityerror systemerror].include?(tempreason)
            # Try to match with message patterns when the temporary reason is "onhold", "undefined",
            # "securityerror", or "systemerror"
            return true if match(diagnostic)
          end
          return false
        end

      end
    end
  end
end



