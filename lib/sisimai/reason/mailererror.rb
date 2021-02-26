module Sisimai
  module Reason
    # Sisimai::Reason::MailerError checks the bounce reason is "mailererror" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that a mailer program has not exited successfully or exited unexpectedly on
    # a destination mail server.
    #
    #   X-Actual-Recipient: X-Unix; |/home/kijitora/mail/catch.php
    #   Diagnostic-Code: X-Unix; 255
    module MailerError
      class << self
        Regex = %r{(?>
           \Aprocmail:[ ]    # procmail
          |bin/(?:procmail|maildrop)
          |command[ ](?:
             failed:[ ]
            |died[ ]with[ ]status[ ]\d+
            |output:
            )
          |exit[ ]\d+
          |mailer[ ]error
          |pipe[ ]to[ ][|][/][^ ]+
          |x[-]unix[;][ ]\d+  # X-UNIX; 127
          )
        }x

        def text; return 'mailererror'; end
        def description; return 'Email returned due to a mailer program has not exited successfully'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if argv1 =~ Regex
          return false
        end

        # The bounce reason is mailer error or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is mailer error
        #                                   false: is not mailer error
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs)
          return nil
        end

      end
    end
  end
end



