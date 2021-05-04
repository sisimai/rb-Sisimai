module Sisimai
  module Reason
    # This is the error that a sent email size is too big for a destination mail server. In many
    # case, There are many attachment files with email, or the file size is too large. Sisimai will
    # set "mesgtoobig" to the reason of email bounce if the value of Status: field in a bounce email
    # is "5.3.4".
    module MesgTooBig
      class << self
        Index = [
          'exceeded maximum inbound message size',
          'line limit exceeded',
          'max message size exceeded',
          'message file too big',
          'message length exceeds administrative limit',
          'message size exceeds fixed limit',
          'message size exceeds fixed maximum message size',
          'message size exceeds maximum value',
          'message too big',
          'message too large for this ',
          'size limit',
          'taille limite du message atteinte',
        ]

        def text; return 'mesgtoobig'; end
        def description; return 'Email rejected due to an email size is too big for a destination mail server'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # The message size is too big for the remote host
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is too big message size
        #                                   false: is not big
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'mesgtoobig'

          statuscode = argvs['deliverystatus'] || ''
          tempreason = Sisimai::SMTP::Status.name(statuscode) || ''

          # Delivery status code points "mesgtoobig".
          # Status: 5.3.4
          # Diagnostic-Code: SMTP; 552 5.3.4 Error: message file too big
          return true if tempreason == 'mesgtoobig'

          #  5.2.3   Message length exceeds administrative limit
          return false if( tempreason == 'exceedlimit' || statuscode == '5.2.3' )

          # Check the value of Diagnosic-Code: header with patterns
          return true if match(argvs['diagnosticcode'].downcase)
          return false
        end

      end
    end
  end
end



