module Sisimai
  module Reason
    # Sisimai::Reason::NotAccept checks the bounce reason is "notaccept" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that a destination mail server does ( or can ) not accept any email. In
    # many case, the server is high load or under the maintenance. Sisimai will set "notaccept" to
    # the reason of email bounce if the value of Status: field in a bounce email is "5.3.2" or the
    # value of SMTP reply code is 556.
    module NotAccept
      class << self
        # Destination mail server does not accept any message
        Index = [
          'host/domain does not accept mail', # iCloud
          'host does not accept mail',        # Sendmail
          'mail receiving disabled',
          'name server: .: host not found',   # Sendmail
          'no mx record found for domain=',   # Oath(Yahoo!)
          'no route for current request',
          'smtp protocol returned a permanent error',
        ]

        def text; return 'notaccept'; end
        def description; return 'Delivery failed due to a destination mail server does not accept any email'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Remote host does not accept any message
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: Not accept
        #                                   false: Accept
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'notaccept'

          # SMTP Reply Code is 554 or 556
          return true if [521, 554, 556].index(argvs['replycode'].to_i)
          return false if argvs['smtpcommand'] == 'MAIL'
          return true if match(argvs['diagnosticcode'].downcase)
          return false
        end

      end
    end
  end
end



