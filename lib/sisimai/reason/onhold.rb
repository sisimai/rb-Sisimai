module Sisimai
  module Reason
    # Sisimai::Reason::OnHold checks the bounce reason is "onhold" or not. This class is called only
    # Sisimai::Reason class. Sisimai will set "onhold" to the reason of email bounce if there is no
    # (or less) detailed information about email bounce for judging the reason.
    module OnHold
      class << self
        def text; return 'onhold'; end
        def description; return 'Sisimai could not decided the reason due to there is no (or less) detailed information for judging the reason'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(_argv1)
          return false
        end

        # On hold, Could not decide the bounce reason...
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: Status code is "onhold"
        #                                   false: is not "onhold"
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil  if argvs['deliverystatus'].empty?
          return true if argvs['reason'] == 'onhold'
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']).to_s == 'onhold'
          return false
        end
      end
    end
  end
end



