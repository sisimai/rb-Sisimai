module Sisimai
  module Reason
    # Sisimai::Reason::Expired checks the bounce reason is "expired" or not. This class is called only
    # Sisimai::Reason class.
    #
    # This is the error that delivery time has expired due to connection failure or network error and
    # the message you sent has been in the queue for long time.
    module Expired
      class << self
        Index = [
          'connection timed out',
          'could not find a gateway for',
          'delivery attempts will continue to be',
          'delivery time expired',
          'failed to deliver to domain ',
          'giving up on',
          'have been failing for a long time',
          'has been delayed',
          'it has not been collected after',
          'message expired after sitting in queue for',
          'message expired, connection refulsed',
          'message timed out',
          'retry time not reached for any host after a long failure period',
          'server did not respond',
          'this message has been in the queue too long',
          'unable to deliver message after multiple retries',
          'was not reachable within the allowed queue period',
          'your message could not be delivered for more than',
        ]

        def text; return 'expired'; end
        def description; return 'Delivery time has expired due to a connection failure'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Delivery expired due to connection failure or network error
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is expired
        #                                   false: is not expired
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs); return nil; end

      end
    end
  end
end


