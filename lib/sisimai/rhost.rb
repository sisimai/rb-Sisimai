module Sisimai
  # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data object as an argument
  # of get() method when the value of rhost of the object is listed in the results of Sisimai::Rhost
  # ->list method. This class is called only Sisimai::Data class.
  module Rhost
    class << self
      RhostClass = {
        '.prod.outlook.com'           => 'ExchangeOnline',
        '.protection.outlook.com'     => 'ExchangeOnline',
        'laposte.net'                 => 'FrancePTT',
        'orange.fr'                   => 'FrancePTT',
        'wanadoo.fr'                  => 'FrancePTT',
        'smtp.secureserver.net'       => 'GoDaddy',
        'mailstore1.secureserver.net' => 'GoDaddy',
        'aspmx.l.google.com'          => 'GoogleApps',
        'gmail-smtp-in.l.google.com'  => 'GoogleApps',
        '.email.ua'                   => 'IUA',
        'lsean.ezweb.ne.jp'           => 'KDDI',
        'msmx.au.com'                 => 'KDDI',
        'charter.net'                 => 'Spectrum',
        'cox.net'                     => 'Cox',
        '.qq.com'                     => 'TencentQQ',
      }.freeze

      # The value of "rhost" is listed in RhostClass or not
      # @param    [String] argvs  Remote host name
      # @return   [True,False]    True: matched
      #                           False: did not match
      def match(rhost)
        return false if rhost.empty?

        host0 = rhost.downcase
        match = false

        RhostClass.each_key do |e|
          # Try to match with each key of RhostClass
          next unless host0.end_with?(e)
          match = true
          break
        end
        return match
      end

      # Detect the bounce reason from certain remote hosts
      # @param    [Hash]   argvs  Parsed email data
      # @param    [String] proxy  The alternative of the "rhost"
      # @return   [String]        The value of bounce reason
      def get(argvs, proxy = nil)
        remotehost = proxy || argvs['rhost'].downcase
        rhostclass = ''
        modulename = ''

        RhostClass.each_key do |e|
          # Try to match with each key of RhostClass
          next unless remotehost.end_with?(e)
          modulename = 'Sisimai::Rhost::' << RhostClass[e]
          rhostclass = modulename.gsub('::', '/').downcase
          break
        end
        return nil if rhostclass.empty?

        require rhostclass
        reasontext = Module.const_get(modulename).get(argvs)
        return reasontext
      end
    end
  end
end

