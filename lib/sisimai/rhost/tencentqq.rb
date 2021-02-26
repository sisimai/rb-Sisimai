module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data object as an argument
    # of get() method when the value of "rhost" of the object is "mx*.qq.com". This class is called
    # only Sisimai::Data class.
    module TencentQQ
      class << self
        MessagesOf = {
          # https://service.mail.qq.com/cgi-bin/help?id=20022
          'dmarc check failed'                    => 'blocked',
          'spf check failed'                      => 'blocked',
          'suspected spam ip'                     => 'blocked',
          'mail is rejected by recipients'        => 'filtered',
          'message too large'                     => 'mesgtoobig',
          'mail content denied'                   => 'spamdetected',
          'spam is embedded in the email'         => 'spamdetected',
          'suspected spam'                        => 'spamdetected',
          'bad address syntax'                    => 'syntaxerror',
          'connection denied'                     => 'toomanyconn',
          'connection frequency limited'          => 'toomanyconn',
          'domain frequency limited'              => 'toomanyconn',
          'ip frequency limited'                  => 'toomanyconn',
          'sender frequency limited'              => 'toomanyconn',
          'mailbox unavailable or access denied'  => 'toomanyconn',
          'mailbox not found'                     => 'userunknown',
        }.freeze

        # Detect bounce reason from Tencent QQ
        # @param    [Sisimai::Data] argvs   Parsed email object
        # @return   [String]                The bounce reason at Tencent QQ
        def get(argvs)
          return argvs['reason'] unless argvs['reason'].empty?

          statusmesg = argvs['diagnosticcode'].downcase
          reasontext = ''

          MessagesOf.each_key do |e|
            # Try to match the error message with message patterns defined in $MessagesOf
            next unless statusmesg.include?(e)
            reasontext = MessagesOf[e]
            break
          end
          return reasontext
        end

      end
    end
  end
end

