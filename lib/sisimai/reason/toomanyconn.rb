module Sisimai
  module Reason
    # Sisimai::Reason::TooManyConn checks the bounce reason is "toomanyconn" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that SMTP connection was rejected temporarily due to too many concurrency
    # connections to the remote server. This reason has added in Sisimai 4.1.26.
    #
    #   <kijitora@example.ne.jp>: host mx02.example.ne.jp[192.0.1.20] said:
    #     452 4.3.2 Connection rate limit exceeded. (in reply to MAIL FROM command)
    module TooManyConn
      class << self
        Index = [
          'all available ips are at maximum connection limit',    # SendGrid
          'connection rate limit exceeded',
          'exceeds per-domain connection limit for',
          'has exceeded the max emails per hour ',
          'throttling failure: daily message quota exceeded',
          'throttling failure: maximum sending rate exceeded',
          'too many connections',
          'too many connections from your host.', # Microsoft
          'too many concurrent smtp connections', # Microsoft
          'too many errors from your ip',         # Free.fr
          'too many recipients',                  # ntt docomo
          'too many smtp sessions for this host', # Sendmail(daemon.c)
          'trop de connexions, ',
          'we have already made numerous attempts to deliver this message',
        ]

        def text; return 'toomanyconn'; end
        def description; return 'SMTP connection rejected temporarily due to too many concurrency connections to the remote host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Rejected by domain or address filter ?
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is filtered
        #                                   false: is not filtered
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'toomanyconn'
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']).to_s == 'toomanyconn'
          return true if match(argvs['diagnosticcode'].downcase)
          return false
        end

      end
    end
  end
end



