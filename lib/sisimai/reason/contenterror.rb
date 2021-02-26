module Sisimai
  module Reason
    # Sisimai::Reason::ContentError checks the bounce reason is "contenterror" or not This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that a destination mail server has rejected email due to header format of the
    # email like the following. Sisimai will set "contenterror" to the reason of email bounce if the
    # value of Status: field in a bounce email is "5.6.*".
    module ContentError
      class << self
        Index = [
          'improper use of 8-bit data in message header',
          'message header size, or recipient list, exceeds policy limit',
          'message mime complexity exceeds the policy maximum',
          'routing loop detected -- too many received: headers',
          'this message contain invalid mime headers',
          'this message contain improperly-formatted binary content',
          'this message contain text that uses unnecessary base64 encoding',
        ]

        def text; return 'contenterror'; end
        def description; return 'Email rejected due to a header format of the email'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Rejected email due to header format of the email
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: rejected due to content error
        #                                   false: is not content error
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs); return nil; end

      end
    end
  end
end

