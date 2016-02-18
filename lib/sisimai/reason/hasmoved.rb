module Sisimai
  module Reason
    # Sisimai::Reason::HasMoved checks the bounce reason is "hasmoved" or not.
    # This class is called only Sisimai::Reason class.
    #
    # This is the error that a user's mailbox has moved (and is not forwarded
    # automatically). Sisimai will set "hasmoved" to the reason of email bounce
    # if the value of Status: field in a bounce email is "5.1.6".
    module HasMoved
      # Imported from p5-Sisimail/lib/Sisimai/Reason/HasMoved.pm
      class << self
        def text; return 'hasmoved'; end
        def description
          return "Email rejected due to user's mailbox has moved and is not forwarded automatically"
        end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r/address[ ].+[ ]has[ ]been[ ]replaced[ ]by[ ]/ix

          return true if argv1 =~ regex
          return false
        end

        # Whether the address has moved or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: The address has moved
        #                                   false: Has not moved
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return true if argvs.reason == Sisimai::Reason::HasMoved.text
          return true if Sisimai::Reason::HasMoved.match(argvs.diagnosticcode)
          return false
        end

      end
    end
  end
end



