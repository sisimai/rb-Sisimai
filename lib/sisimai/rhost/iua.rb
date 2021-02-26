module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data object as an argument
    # of get() method when the value of "rhost" of the object is "*.email.ua". This class is called
    # only Sisimai::Data class.
    module IUA
      class << self
        ErrorCodes = {
          # http://mail.i.ua/err/$(CODE)
          '1'  => 'norelaying',  # The use of SMTP as mail gate is forbidden.
          '2'  => 'userunknown', # User is not found.
          '3'  => 'suspend',     # Mailbox was not used for more than 3 months
          '4'  => 'mailboxfull', # Mailbox is full.
          '5'  => 'toomanyconn', # Letter sending limit is exceeded.
          '6'  => 'norelaying',  # Use SMTP of your provider to send mail.
          '7'  => 'blocked',     # Wrong value if command HELO/EHLO parameter.
          '8'  => 'rejected',    # Couldn't check sender address.
          '9'  => 'blocked',     # IP-address of the sender is blacklisted.
          '10' => 'filtered',    # Not in the list Mail address management.
        }.freeze

        # Detect bounce reason from https://www.i.ua/
        # @param    [Sisimai::Data] argvs   Parsed email object
        # @return   [String]                The bounce reason at https://www.i.ua/
        def get(argvs)
          return argvs['reason'] unless argvs['reason'].empty?

          if cv = argvs['diagnosticcode'].downcase.match(%r|[.]i[.]ua/err/(\d+)|)
            return ErrorCodes[cv[1]] || ''
          end
          return ''
        end

      end
    end
  end
end

