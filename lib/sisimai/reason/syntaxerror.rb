module Sisimai
  module Reason
    # Sisimai::Reason::SyntaxError checks the bounce reason is "syntaxerror" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that a destination mail server could not recognize SMTP command which is
    # sent from a sender's MTA. Sisimai will set "syntaxerror" to the reason if the value of
    # "replycode" begins with "50" such as 502, or 503.
    #   Action: failed
    #   Status: 5.5.0
    #   Diagnostic-Code: SMTP; 503 Improper sequence of commands
    #
    module SyntaxError
      class << self
        def text; return 'syntaxerror'; end
        def description; return 'Email rejected due to syntax error at sent commands in SMTP session'; end
        def match(*); return nil; end

        # Connection rejected due to syntax error or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: Connection rejected due to
        #                                         syntax error
        #                                   false: is not syntax error
        # @since 4.1.25
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'syntaxerror'
          return true if argvs['replycode'] =~ /\A[45]0[1-7]\z/
          return false
        end

      end
    end
  end
end

