module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data object as an argument
    # of get() method when the value of "rhost" of the object is "lsean.ezweb.ne.jp" or "msmx.au.com".
    # This class is called only Sisimai::Data class.
    module KDDI
      class << self
        MessagesOf = {
          'filtered'    => '550 : User unknown',  # The response was: 550 : User unknown
          'userunknown' => '>: User unknown',     # The response was: 550 <...>: User unknown
        }.freeze

        # Detect bounce reason from au (KDDI)
        # @param    [Sisimai::Data] argvs   Parsed email object
        # @return   [String]                The bounce reason for au.com or ezweb.ne.jp
        def get(argvs)
          statusmesg = argvs['diagnosticcode']
          reasontext = ''

          MessagesOf.each_key do |e|
            # Try to match the error message with message patterns defined in $MessagesOf
            next unless statusmesg.end_with?(MessagesOf[e])
            reasontext = e
            break
          end

          return reasontext
        end

      end
    end
  end
end


