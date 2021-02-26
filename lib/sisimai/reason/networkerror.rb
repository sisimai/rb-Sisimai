module Sisimai
  module Reason
    # Sisimai::Reason::NetworkError checks the bounce reason is "networkerror" or not. This class is
    # called only Sisimai::Reason class. This is the error that SMTP connection failed due to DNS
    # look up failure or other network problems.
    #
    #   A message is delayed for more than 10 minutes for the following
    #   list of recipients:
    #
    #   kijitora@neko.example.jp: Network error on destination MXs
    module NetworkError
      class << self
        Index = [
          'could not connect and send the mail to',
          'dns records for the destination computer could not be found',
          'hop count exceeded - possible mail loop',
          'host is unreachable',
          'host not found, try again',
          'mail forwarding loop for ',
          'malformed name server reply',
          'malformed or unexpected name server reply',
          'maximum forwarding loop count exceeded',
          'message looping',
          'message probably in a routing loop',
          'no route to host',
          'too many hops',
          'unable to resolve route ',
          'unrouteable mail domain',
        ]

        def text; return 'networkerror'; end
        def description; return 'SMTP connection failed due to DNS look up failure or other network problems'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # The bounce reason is network error or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is network error
        #                                   false: is not network error
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs)
          return nil
        end

      end
    end
  end
end



