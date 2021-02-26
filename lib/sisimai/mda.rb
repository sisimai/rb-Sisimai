module Sisimai
  # Sisimai::MDA - Error message parser for MDA
  module MDA
    class << self
      AgentNames = {
        # dovecot/src/deliver/deliver.c
        # 11: #define DEFAULT_MAIL_REJECTION_HUMAN_REASON \
        # 12: "Your message to <%t> was automatically rejected:%n%r"
        'dovecot'    => %r/\AYour message to [^ ]+ was automatically rejected:\z/,
        'mail.local' => %r/\Amail[.]local: /,
        'procmail'   => %r/\Aprocmail: /,
        'maildrop'   => %r/\Amaildrop: /,
        'vpopmail'   => %r/\Avdelivermail: /,
        'vmailmgr'   => %r/\Avdeliver: /,
      }.freeze
      MarkingsOf = {
        message: %r{\A(?>
           Your[ ]message[ ]to[ ][^ ]+[ ]was[ ]automatically[ ]rejected:\z
          |(?:mail[.]local|procmail|maildrop|vdelivermail|vdeliver):[ ]
          )
        }x
      }.freeze

      # dovecot/src/deliver/mail-send.c:94
      MessagesOf = {
        'dovecot' => {
          'userunknown' => ["mailbox doesn't exist: "],
          'mailboxfull' => [
            'quota exceeded',   # Dovecot 1.2 dovecot/src/plugins/quota/quota.c
            'quota exceeded (mailbox for user is full)',    # dovecot/src/plugins/quota/quota.c
            'not enough disk space',
          ],
        },
        'mail.local' => {
          'userunknown' => [
            ': unknown user:',
            ': user unknown',
            ': invalid mailbox path',
            ': user missing home directory',
          ],
          'mailboxfull' => [
            'disc quota exceeded',
            'mailbox full or quota exceeded',
          ],
          'systemerror' => ['temporary file write error'],
        },
        'procmail' => {
          'mailboxfull' => ['quota exceeded while writing'],
          'systemfull'  => ['no space left to finish writing'],
        },
        'maildrop' => {
          'userunknown' => [
            'invalid user specified.',
            'Cannot find system user',
          ],
          'mailboxfull' => ['maildir over quota.'],
        },
        'vpopmail' => {
          'userunknown' => ['sorry, no mailbox here by that name.'],
          'filtered'    => [
            'account is locked email bounced',
            'user does not exist, but will deliver to '
          ],
          'mailboxfull' => ['domain is over quota', 'user is over quota'],
        },
        'vmailmgr' => {
          'userunknown' => [
            'invalid or unknown base user or domain',
            'invalid or unknown virtual user',
            'user name does not refer to a virtual user'
          ],
          'mailboxfull' => ['delivery failed due to system quota violation'],
        },
      }.freeze

      # Parse message body and return reason and text
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['from'].downcase.start_with?('mail delivery subsystem','mailer-daemon', 'postmaster')

        agentname0 = ''   # [String] MDA name
        reasonname = ''   # [String] Error reason
        bouncemesg = ''   # [String] Error message
        bodyslices = mbody.split("\n")
        linebuffer = []

        while e = bodyslices.shift do
          # Check each line with each MDA's symbol regular expression.
          if agentname0 == ''
            # Try to match with each regular expression
            next if e.empty?
            next unless e =~ MarkingsOf[:message]

            AgentNames.each_key do |f|
              # Detect the agent name from the line
              next unless e =~ AgentNames[f]
              agentname0 = f
              break
            end
          end

          # Append error message lines to @linebuffer
          linebuffer << e
          break if e.empty?
        end
        return nil if agentname0.empty?
        return nil if linebuffer.empty?

        MessagesOf[agentname0].each_key do |e|
          # Detect an error reason from message patterns of the MDA.
          duplicated = linebuffer.dup
          while f = duplicated.shift do
            # Whether the error message include each message defined in $MessagesOf
            next unless MessagesOf[agentname0][e].any? { |a| f.downcase.include?(a) }
            reasonname = e
            bouncemesg = f
            break
          end
          break if bouncemesg.size > 0 && reasonname.size > 0
        end

        return {
          'mda'     => agentname0,
          'reason'  => reasonname || '',
          'message' => bouncemesg || '',
        }
      end
    end
  end
end

