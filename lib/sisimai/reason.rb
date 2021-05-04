module Sisimai
  # Sisimai::Reason detects the bounce reason from the Hash table which is to be constructed to 
  # Sisimai::Fact object as an argument of get() method. This class is called only Sisimai::Fact class.
  module Reason
    class << self
      # All the error reason list Sisimai support
      # @return   [Array] Reason list
      def index
        return %w[
          Blocked ContentError ExceedLimit Expired Filtered HasMoved HostUnknown MailboxFull
          MailerError MesgTooBig NetworkError NotAccept OnHold Rejected NoRelaying SpamDetected
          VirusDetected PolicyViolation SecurityError Suspend SystemError SystemFull TooManyConn
          UserUnknown SyntaxError
        ]
      end

      # @abstract Returns Sisimai::Reason::* module path table
      # @return   [Hash] Module path table
      # @since    v4.25.6
      def path
        index = Sisimai::Reason.index
        table = {}
        index.each { |e| table['Sisimai::Reason::' << e] = 'sisimai/reason/' << e.downcase }
        return table
      end

      # Reason list better to retry detecting an error reason
      # @return   [Array] Reason list
      def retry
        return {
          'undefined' => true, 'onhold' => true, 'systemerror' => true, 'securityerror' => true,
          'networkerror' => true, 'hostunknown' => true, 'userunknown' => true
        }.freeze
      end
      ModulePath = Sisimai::Reason.path
      GetRetried = Sisimai::Reason.retry
      ClassOrder = [
        %w[
          MailboxFull MesgTooBig ExceedLimit Suspend HasMoved NoRelaying UserUnknown Filtered
          Rejected HostUnknown SpamDetected TooManyConn Blocked
        ],
        %w[
          MailboxFull SpamDetected PolicyViolation VirusDetected NoRelaying SecurityError
          SystemError NetworkError Suspend Expired ContentError SystemFull NotAccept MailerError
        ],
        %w[
          MailboxFull MesgTooBig ExceedLimit Suspend UserUnknown Filtered Rejected HostUnknown
          SpamDetected TooManyConn Blocked SpamDetected SecurityError SystemError NetworkError
          Suspend Expired ContentError HasMoved SystemFull NotAccept MailerError NoRelaying
          SyntaxError OnHold
        ]
      ]

      # Detect the bounce reason
      # @param    [Hash] argvs  Parsed email object
      # @return   [String, nil] Bounce reason or nil if the argument is missing or not Hash
      # @see anotherone
      def get(argvs)
        return nil unless argvs
        unless GetRetried[argvs['reason']]
          # Return reason text already decided except reason match with the regular expression of
          # retry() method.
          return argvs['reason'] unless argvs['reason'].empty?
        end
        return 'delivered' if argvs['deliverystatus'].start_with?('2.')

        reasontext = ''
        if argvs['diagnostictype'] == 'SMTP' || argvs['diagnostictype'] == ''
          # Diagnostic-Code: SMTP; ... or empty value
          ClassOrder[0].each do |e|
            # Check the value of Diagnostic-Code: and the value of Status:, it is a deliverystats,
            # with true() method in each Sisimai::Reason::* class.
            p = 'Sisimai::Reason::' << e
            r = nil
            begin
              require ModulePath[p]
              r = Module.const_get(p)
            rescue
              warn ' ***warning: Failed to load ' << p
              next
            end
            next unless r.true(argvs)
            reasontext = r.text
            break
          end
        end

        if reasontext.empty? || reasontext == 'undefined'
          # Bounce reason is not detected yet.
          reasontext = self.anotherone(argvs)

          if reasontext == 'undefined' || reasontext.empty?
            # Action: delayed => "expired"
            reasontext   = nil
            reasontext ||= 'expired' if argvs['action'] == 'delayed'
            return reasontext if reasontext

            # Try to match with message patterns in Sisimai::Reason::Vacation
            require 'sisimai/reason/vacation'
            reasontext   = 'vacation' if Sisimai::Reason::Vacation.match(argvs['diagnosticcode'].downcase)
            reasontext ||= 'onhold'   unless argvs['diagnosticcode'].empty?
            reasontext ||= 'undefined'
          end
        end
        return reasontext
      end

      # Detect the other bounce reason, fall back method for get()
      # @param    [Hash] argvs  Parsed email object
      # @return   [String, Nil] Bounce reason or nli if the argument is missing or not Hash
      # @see get
      def anotherone(argvs)
        return argvs['reason'] unless argvs['reason'].empty?

        require 'sisimai/smtp/status'
        statuscode = argvs['deliverystatus'] || ''
        reasontext = Sisimai::SMTP::Status.name(statuscode) || ''

        catch :TRY_TO_MATCH do
          while true
            diagnostic   = argvs['diagnosticcode'].downcase || ''
            trytomatch   = reasontext.empty? ? true : false
            trytomatch ||= true if GetRetried[reasontext]
            trytomatch ||= true if argvs['diagnostictype'] != 'SMTP'
            throw :TRY_TO_MATCH unless trytomatch

            # Could not decide the reason by the value of Status:
            ClassOrder[1].each do |e|
              # Trying to match with other patterns in Sisimai::Reason::* classes
              p = 'Sisimai::Reason::' << e
              r = nil
              begin
                require ModulePath[p]
                r = Module.const_get(p)
              rescue
                warn ' ***warning: Failed to load ' << p
                next
              end

              next unless r.match(diagnostic)
              reasontext = e.downcase
              break
            end
            throw :TRY_TO_MATCH unless reasontext.empty?

            # Check the value of Status:
            v = statuscode[0, 3]
            if v == '5.6' || v == '4.6'
              #  X.6.0   Other or undefined media error
              reasontext = 'contenterror'

            elsif v == '5.7' || v == '4.7'
              #  X.7.0   Other or undefined security status
              reasontext = 'securityerror'

            elsif %w[X-UNIX X-POSTFIX].include?(argvs['diagnostictype'])
              # Diagnostic-Code: X-UNIX; ...
              reasontext = 'mailererror'
            else
              # 50X Syntax Error?
              require 'sisimai/reason/syntaxerror'
              reasontext = 'syntaxerror' if Sisimai::Reason::SyntaxError.true(argvs)
            end
            throw :TRY_TO_MATCH unless reasontext.empty?

            # Check the value of Action: field, first
            if argvs['action'].start_with?('delayed', 'expired')
              # Action: delayed, expired
              reasontext = 'expired'
            else
              # Rejected at connection or after EHLO|HELO
              commandtxt = argvs['smtpcommand'] || ''
              reasontext = 'blocked' if %w[HELO EHLO].index(commandtxt)
            end
            throw :TRY_TO_MATCH
          end
        end
        return reasontext
      end

      # Detect the bounce reason from given text
      # @param    [String] argv1  Error message
      # @return   [String]        Bounce reason
      def match(argv1)
        return nil unless argv1

        reasontext = ''
        diagnostic = argv1.downcase

        # Diagnostic-Code: SMTP; ... or empty value
        ClassOrder[2].each do |e|
          # Check the value of Diagnostic-Code: and the value of Status:, it is a deliverystats, with
          # true() method in each Sisimai::Reason::* class.
          p = 'Sisimai::Reason::' << e
          r = nil
          begin
            require ModulePath[p]
            r = Module.const_get(p)
          rescue
            warn ' ***warning: Failed to load ' << p
            next
          end

          next unless r.match(diagnostic)
          reasontext = r.text
          break
        end
        return reasontext unless reasontext.empty?

        typestring = ''
        if cv = argv1.match(/\A(SMTP|X-.+);/i)
          # Check the value of typestring
          typestring = cv[1].upcase
        end

        if typestring == 'X-UNIX'
          # X-Unix; ...
          reasontext = 'mailererror'
        else
          # Detect the bounce reason from "Status:" code
          require 'sisimai/smtp/status'
          statuscode = Sisimai::SMTP::Status.find(argv1) || ''
          reasontext = Sisimai::SMTP::Status.name(statuscode) || 'undefined'
        end
        return reasontext
      end

    end
  end
end

