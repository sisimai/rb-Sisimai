module Sisimai
  module Reason
    # Sisimai::Reason::SecurityError checks the bounce reason is "securityerror" or not. This class
    # is called only Sisimai::Reason class.
    #
    # This is the error that a security violation was detected on a destination mail server. Depends
    # on the security policy on the server, a sender's email address is camouflaged address.
    #
    # Sisimai will set "securityerror" to the reason of email bounce if the value of Status: field
    # in a bounce email is "5.7.*".
    #
    #   Action: failed
    #   Status: 5.7.1
    #   Remote-MTA: DNS; gmail-smtp-in.l.google.com
    #   Diagnostic-Code: SMTP; 552-5.7.0 Our system detected an illegal attachment on your message. Please
    #   Last-Attempt-Date: Tue, 28 Apr 2009 11:02:45 +0900 (JST)
    #
    module SecurityError
      class << self
        Regex = %r{(?>
           account[ ]not[ ]subscribed[ ]to[ ]ses
          |authentication[ ](?:
             credentials invalid
            |failure
            |failed;[ ]server[ ][^ ]+[ ]said: # Postfix
            |required
            |turned[ ]on[ ]in[ ]your[ ]email[ ]client
            )
          |\d+[ ]denied[ ]\[[a-z]+\][ ].+[(]mode:[ ].+[)]
          |authentification[ ]requise.+[0-9a-z_]+402
          |codes?[ ]d'?[ ]*authentification[ ]invalide.+[0-9a-z_]+305
          |domain[ ][^ ]+[ ]is[ ]a[ ]dead[ ]domain
          |executable[ ]files[ ]are[ ]not[ ]allowed[ ]in[ ]compressed[ ]files
          |insecure[ ]mail[ ]relay
          |recipient[ ]address[ ]rejected:[ ]access[ ]denied
          |sorry,[ ]you[ ]don'?t[ ]authenticate[ ]or[ ]the[ ]domain[ ]isn'?t[ ]in[ ]
            my[ ]list[ ]of[ ]allowed[ ]rcpthosts
          |tls[ ]required[ ]but[ ]not[ ]supported # SendGrid:the recipient mailserver does not support TLS or have a valid certificate
          |tls[ ]required[ ]but[ ]not[ ]supported # SendGrid:the recipient mailserver does not support TLS or have a valid certificate
          |unauthenticated[ ]senders[ ]not[ ]allowed
          |user[ ][^ ]+[ ]is[ ]not[ ]authorized[ ]to[ ]perform[ ]ses:sendrawemail[ ]on[ ]resource
          |you[ ]are[ ]not[ ]authorized[ ]to[ ]send[ ]mail,[ ]authentication[ ]is[ ]required
          |verification[ ]failure
          )
        }x

        def text; return 'securityerror'; end
        def description; return 'Email rejected due to security violation was detected on a destination host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if argv1 =~ Regex
          return false
        end

        # The bounce reason is security error or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is security error
        #                                   false: is not security error
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs)
          return nil
        end

      end
    end
  end
end

