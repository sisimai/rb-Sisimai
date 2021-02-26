require 'minitest'
class LhostCode < Minitest::Test
  Lo = self.new("LHOST-ENGINE-TEST")

  def initialize(v = ''); return super(v); end
  def enginetest(enginename = nil, isexpected = {}, privateset = false, onlydebugs = 0)
    return nil unless enginename
    return nil if isexpected.empty?

    assert_instance_of String, enginename
    assert_instance_of   Hash, isexpected

    require 'sisimai/mail'
    require 'sisimai/fact'
    require 'sisimai/lhost'
    require 'sisimai/reason'
    require 'sisimai/address'

    lhostindex = Sisimai::Lhost.index; lhostindex << 'ARF' << 'RFC3464' << 'RFC3834'
    isnotlhost = %w[ARF RFC3464 RFC3834]
    methodlist = %w[inquire]
    samplepath = 'set-of-emails/maildir/bsd'
    modulepath = ''
    modulename = ''
    currmodule = nil
    emailindex = 0
    nameprefix = ''
    reasonlist = Sisimai::Reason.index.map { |e| e = e.downcase }
    reasonlist << "delivered" << "feedback" << "undefined" << "vacation"
    skiptonext = {
      'public'  => %w[lhost-postfix-49 lhost-postfix-50],
      'private' => %w[
        arf/01003 arf/01005 arf/01009 arf/01015
        lhost-exim/01084 lhost-mailmarshalsmtp/01001
        lhost-postfix/01200 lhost-postfix/01201
        rfc3464/01024 rfc3464/01061 rfc3464/01081
      ],
    }

    if isnotlhost.include?(enginename)
      # ARF, RFC3464, RFC3834
      modulepath = 'sisimai/' << enginename.downcase
      modulename = 'Sisimai::' << enginename
    else
      # Sisimai::Lhost or Sisimai::Rhost
      nameprefix = caller[0].include?('/lhost-engine-test') ? 'Lhost' : 'Rhost'
      modulepath = 'sisimai/' << nameprefix.downcase << '/' << enginename.downcase
      modulename = 'Sisimai::' << nameprefix << '::' << enginename
      nameprefix = nameprefix.downcase + '-'
    end
    require modulepath
    currmodule = Module.const_get(modulename)
    samplepath = sprintf("set-of-emails/private/%s%s", nameprefix, enginename.downcase) if privateset

    if modulename.include?('::Lhost::')
      # Sisimai::Lhost::*.inquire
      assert_respond_to currmodule, 'inquire'

    elsif modulename.include?('::Rhost::')
      # Sisimai::Rhost::*.get
      assert_respond_to currmodule, 'get'
    end

    isexpected.keys.sort.each do |e|
      # Open each eamil in set-of-emails/ directory
      ce = modulename
      cf = '' # Path to the email file to be tested
      cx = isexpected[e]

      if onlydebugs > 0
        # DEBUG: Test the email which have a specified number
        emailindex += 1
        next unless onlydebugs == e.to_i
        assert_equal true, e.to_i > 0, sprintf("%s [%s---] DEBUG", ce, e)
      end

      if privateset
        # Private sample: 01227-581a7c3e4f0c0664ff171969c34bf988.eml
        if isnotlhost.include?(enginename)
          cf = Dir.glob(sprintf("./%s%s/%s-*.eml", samplepath, nameprefix, e)).shift
        else
          cf = Dir.glob(sprintf("./%s/%s-*.eml", samplepath, e)).shift
        end
      else
        # Public sample: lhost-sendmail-59.eml
        cf = sprintf("./%s/%s%s-%02d.eml", samplepath, nameprefix, enginename.downcase, e.to_i)
      end

      assert_equal true, File.exist?(cf),   sprintf("%s [%s---] email(path) = %s", ce, e, cf)
      assert_equal true, File.size(cf) > 0, sprintf("%s [%s---] email(size) = %d", ce, e, File.size(cf))

      assert_instance_of Array, cx
      refute_empty cx

      mailobject = Sisimai::Mail.new(cf)
      assert_instance_of Sisimai::Mail, mailobject

      while r = mailobject.data.read do
        # Read messages in each email
        listoffact = Sisimai::Fact.rise(data: r, delivered: true, origin: cf)

        unless listoffact
          if privateset
            bf = cf.split('/', 4)[-1].sub(/[-][0-9a-f]{32}[.]eml\z/, '')
            next if skiptonext['private'].include?(bf)
          else
            bf = cf.split('/')[-1].sub(/[.]eml\z/, '')
            next if skiptonext['public'].include?(File.basename(bf))
          end
        end

        recipients = listoffact.size
        errorindex = 0

        assert_instance_of String, r
        assert_instance_of Array, listoffact
        refute_empty listoffact,           sprintf("%s [%s---] parsed %s", ce, e, cf)
        assert_equal true, recipients > 0, sprintf("%s [%s---] including %d bounces", ce, e, recipients)

        listoffact.each do |rr|
          # Test each Sisimai::Fact object
          errorindex += 1
          assert_instance_of Sisimai::Fact, rr

          # ---------------------------------------------------------------------------------------
          # ACTION
          cv = rr.action
          cr = %r/\A(?:delayed|delivered|expanded|failed|relayed)\z/
          ct = sprintf("%s [%s-%02d] #action =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil cv, sprintf("%s %s", ct, cv)
          if %w[feedback vacation].include?(rr.reason)
            # "action" is empty when the value of "reason" is "feedback" OR "vacation"
            assert_empty cv, sprintf("%s %s", ct, cv)
          else
            # The value of "reason" is not "feedback"
            assert_match cr, cv, sprintf("%s %s", ct, cr)
          end

          # ---------------------------------------------------------------------------------------
          # ADDRESSER
          cv = rr.addresser.address
          cr = %r/\A.+[@][0-9A-Za-z._-]+[A-Za-z]+?\z/;
          ct = sprintf("%s [%s-%02d] #addresser.", ce, e, errorindex)

          assert_instance_of Sisimai::Address, rr.addresser
          refute_nil rr.addresser.alias,   sprintf("%s%s = %s", ct, 'alias', rr.addresser.alias)
          refute_nil rr.addresser.verp,    sprintf("%s%s = %s", ct, 'verp',  rr.addresser.verp)
          refute_nil rr.addresser.name,    sprintf("%s%s = %s", ct, 'name',  rr.addresser.name)
          refute_nil rr.addresser.comment, sprintf("%s%s = %s", ct, 'comment',  rr.addresser.comment)
          refute_empty rr.addresser.user,  sprintf("%s%s = %s", ct, 'user',  rr.addresser.user)

          unless Sisimai::Address.is_mailerdaemon(cv)
            # Is not a MAILER-DAEMON
            refute_empty rr.addresser.host, sprintf("%s%s = %s", ct, 'host', rr.addresser.host)
            refute_empty cv,                sprintf("%s%s = %s", ct, 'address', cv)
            assert_match cr, cv,            sprintf("%s%s = %s", ct, 'address', cv)

            assert_equal rr.addresser.user + '@' + rr.addresser.host, cv
            assert_match cr, rr.addresser.alias unless rr.addresser.alias.empty?
            assert_match cr, rr.addresser.verp  unless rr.addresser.verp.empty?
          end

          # ---------------------------------------------------------------------------------------
          # ALIAS
          cv = rr.alias
          ct = sprintf("%s [%s-%02d] #alias =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil cv, sprintf("%s %s", ct, cv)

          # ---------------------------------------------------------------------------------------
          # CATCH
          assert_nil rr.catch, sprintf("%s [%s-%02d] #catch = nil", ce, e, errorindex)

          # ---------------------------------------------------------------------------------------
          # DELIVERYSTATUS
          cv = rr.deliverystatus
          cr = %r/\A[245][.]\d[.]\d{1,3}\z/
          ct = sprintf("%s [%s-%02d] #deliverystatus =", ce, e, errorindex)

          assert_instance_of String, cv
          if %w[feedback vacation].include?(rr.reason)
            # "deliverystatus" is empty when the value of "reason" is "feedback"
            assert_empty cv, sprintf("%s %s", ct, cv)
          else
            # Except the value of "reason" is "feedback"
            refute_empty cv,     sprintf("%s %s", ct, cv)
            assert_match cr, cv, sprintf("%s %s", ct, cv)
          end
          assert_equal cx[errorindex - 1][0], cv, sprintf("%s %s", ct, cv)

          # ---------------------------------------------------------------------------------------
          # DESTINATION
          cv = rr.destination
          cr = %r/\A[-_.0-9A-Za-z]+\z/
          ct = sprintf("%s [%s-%02d] #destination =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_empty cv,     sprintf("%s %s", ct, cv)
          assert_match cr, cv, sprintf("%s %s", ct, cv)
          assert_equal rr.recipient.host, cv, sprintf("%s recipient.host", ct)

          # ---------------------------------------------------------------------------------------
          # DIAGNOSTICCODE
          cv = rr.diagnosticcode
          ct = sprintf("%s [%s-%02d] #diagnosticcode =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil cv, sprintf("%s %s", ct, cv)

          # ---------------------------------------------------------------------------------------
          # DIAGNOSTICTYPE
          cv = rr.diagnostictype
          cr = %r/\A(?:LMTP|SMTP|UNKNOWN|X[.]?[45]00|X-[0-9A-Z-]+)/
          ct = sprintf("%s [%s-%02d] #diagnostictype =", ce, e, errorindex)

          assert_instance_of String, cv
          if %w[feedback vacation].include?(rr.reason)
            # "deliverystatus" is empty when the value of "reason" is "feedback"
            refute_nil cv, sprintf("%s %s", ct, cv)
          else
            # Except the value of "reason" is "feedback"
            refute_empty cv,     sprintf("%s %s", ct, cv)
            assert_match cr, cv, sprintf("%s %s", ct, cv)
          end

          # ---------------------------------------------------------------------------------------
          # FEEDBACKTYPE
          cv = rr.feedbacktype
          cr = %r/\A[\x21-\x7e]+\z/
          ct = sprintf("%s [%s-%02d] #feedbacktype =", ce, e, errorindex)

          assert_instance_of String, cv
          if rr.reason == 'feedback'
            # The value of "feedbacktype" is not empty
            refute_empty cv,                        sprintf("%s %s", ct, cv)
            assert_match cr, cv,                    sprintf("%s %s", ct, cv)
            assert_equal cx[errorindex - 1][4], cv, sprintf("%s %s", ct, cv)
          else
            # The value of "feedbacktype" is empty
            assert_empty cv, sprintf("%s %s", ct, cv)
          end

          # ---------------------------------------------------------------------------------------
          # HARDBOUNCE
          cv = rr.hardbounce
          ct = sprintf("%s [%s-%02d] #hardbounce =", ce, e, errorindex)

          assert_includes [true, false], cv,      sprintf("%s %s", ct, cv.to_s)
          assert_equal cx[errorindex - 1][3], cv, sprintf("%s %s", ct, cv.to_s)

          # ---------------------------------------------------------------------------------------
          # LHOST
          cv = rr.lhost
          cr = %r/\A[\x21-\x7e]+\z/
          ct = sprintf("%s [%s-%02d] #lhost =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil       cv, sprintf("%s %s", ct, cv)
          assert_match cr, cv, sprintf("%s %s", ct, cv) unless cv.empty?

          # ---------------------------------------------------------------------------------------
          # LISTID
          cv = rr.listid
          cr = %r/\A[\x21-\x7e]+\z/
          ct = sprintf("%s [%s-%02d] #listid =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil cv, sprintf("%s %s", ct, cv)
          assert_match cr, cv, sprintf("%s %s", ct, cv) unless cv.empty?

          # ---------------------------------------------------------------------------------------
          # MESSAGEID
          cv = rr.messageid
          cr = %r/\A[\x21-\x7e]+\z/
          ct = sprintf("%s [%s-%02d] #messageid =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil cv, sprintf("%s %s", ct, cv)
          assert_match cr, cv, sprintf("%s %s", ct, cv) unless cv.empty?

          # ---------------------------------------------------------------------------------------
          # ORIGIN
          cv = rr.origin
          ct = sprintf("%s [%s-%02d] #origin =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_empty                    cv, sprintf("%s %s", ct, cv)
          assert_equal true, File.exist?(cv), sprintf("%s %s", ct, cv) unless cv.empty?
          assert_equal true, File.size(cv)>0, sprintf("%s %dKB", ct, File.size(cv))

          # ---------------------------------------------------------------------------------------
          # REASON
          cv = rr.reason
          ct = sprintf("%s [%s-%02d] #reason =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_empty cv,                        sprintf("%s %s", ct, cv)
          assert_includes reasonlist, cv,         sprintf("%s %s", ct, cv)
          assert_equal cx[errorindex - 1][2], cv, sprintf("%s %s", ct, cv)

          # ---------------------------------------------------------------------------------------
          # RECIPIENT
          cv = rr.recipient.address
          cr = %r/\A.+[@][0-9A-Za-z._-]+[A-Za-z]+?\z/;
          ct = sprintf("%s [%s-%02d] #recipient.", ce, e, errorindex)

          assert_instance_of Sisimai::Address, rr.recipient
          refute_nil rr.recipient.alias,   sprintf("%s%s = %s", ct, 'alias', rr.recipient.alias)
          refute_nil rr.recipient.verp,    sprintf("%s%s = %s", ct, 'verp',  rr.recipient.verp)
          refute_nil rr.recipient.name,    sprintf("%s%s = %s", ct, 'name',  rr.recipient.name)
          refute_nil rr.recipient.comment, sprintf("%s%s = %s", ct, 'comment',  rr.recipient.comment)
          refute_empty rr.recipient.user,  sprintf("%s%s = %s", ct, 'user',  rr.recipient.user)
          refute_empty rr.recipient.host,  sprintf("%s%s = %s", ct, 'host',  rr.recipient.host)

          refute_empty cv,     sprintf("%s%s = %s", ct, 'address', cv)
          assert_match cr, cv, sprintf("%s%s = %s", ct, 'address', cv)
          assert_equal rr.recipient.user + '@' + rr.recipient.host, cv
          refute_empty rr.recipient.alias unless rr.recipient.alias.empty?
          refute_empty rr.recipient.verp  unless rr.recipient.verp.empty?

          # ---------------------------------------------------------------------------------------
          # REPLYCODE
          cv = rr.replycode
          cr = %r/\A[245]\d\d\z/
          ct = sprintf("%s [%s-%02d] #replycode =", ce, e, errorindex)

          assert_instance_of String, cv
          unless cv.empty?
            assert_match cr, cv, sprintf("%s %s", ct, cv)
            assert_equal rr.deliverystatus[0,1], cv[0,1], sprintf("%s %dXX", ct, cv[0,1].to_i)
          end
          assert_equal cx[errorindex - 1][1], cv, sprintf("%s %s", ct, cv)

          # ---------------------------------------------------------------------------------------
          # RHOST
          cv = rr.rhost
          cr = %r/\A[-.:0-9A-Za-z]+\z/
          ct = sprintf("%s [%s-%02d] #rhost =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil       cv, sprintf("%s %s", ct, cv)
          assert_match cr, cv, sprintf("%s %s", ct, cv) unless cv.empty?

          # ---------------------------------------------------------------------------------------
          # SENDERDOMAIN
          cv = rr.senderdomain
          cr = %r/\A[-_.0-9A-Za-z]+\z/
          ct = sprintf("%s [%s-%02d] #senderdomain =", ce, e, errorindex)

          assert_instance_of String, cv
          unless Sisimai::Address.is_mailerdaemon(rr.addresser.address)
            refute_empty cv,                    sprintf("%s %s", ct, cv)
            assert_match cr, cv,                sprintf("%s %s", ct, cv)
            assert_equal rr.addresser.host, cv, sprintf("%s addresser.host", ct)
          end

          # ---------------------------------------------------------------------------------------
          # SMTPAGENT
          cv = rr.smtpagent
          cr = %r/\A[-.0-9A-Za-z]+\z/
          ct = sprintf("%s [%s-%02d] #smtpagent =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_empty cv,     sprintf("%s %s", ct, cv)

          if nameprefix.start_with?('rhost')
            # Sisimai::Rhost
            assert_match cr, cv, sprintf("%s %s", ct, cv)
          else
            # Sisimai::Lhost 
            if enginename == 'RFC3464' && cv !~ /\ARFC3464/
              # Parsed by Sisimai::MDA
              assert_match cr, cv, sprintf("%s %s", ct, cv)
              assert_empty lhostindex.select { |p| cv == p }
            elsif enginename == 'ARF'
              # Parsed by Sisimai::ARF
              assert_equal 'Feedback-Loop', cv, sprintf("%s %s", ct, cv)
            else
              # Other MTA modules
              assert_equal enginename.upcase, cv.upcase, sprintf("%s %s", ct, cv)
            end
          end

          # ---------------------------------------------------------------------------------------
          # SMTPCOMMAND
          cv = rr.smtpcommand
          cr = %w[CONN HELO EHLO MAIL RCPT DATA QUIT]
          ct = sprintf("%s [%s-%02d] #smtpcommand =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil cv, sprintf("%s %s", ct, cv)
          assert_includes cr, cv, sprintf("%s %s", ct, cv) unless cv.empty?

          # ---------------------------------------------------------------------------------------
          # SUBJECT
          cv = rr.subject
          ct = sprintf("%s [%s-%02d] #subject =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_nil cv, sprintf("%s %s", ct, cv)

          # ---------------------------------------------------------------------------------------
          # TIMESTAMP
          cv = rr.timestamp
          ct = sprintf("%s [%s-%02d] #timestamp =", ce, e, errorindex)

          assert_instance_of Sisimai::Time, cv
          assert_equal true, cv.to_json > 0, sprintf("%s %d", ct, cv.to_json)
          refute_empty cv.rfc2822,           sprintf("%s %s", ct, cv.rfc2822)

          # ---------------------------------------------------------------------------------------
          # TIMEZONEOFFSET
          cv = rr.timezoneoffset
          cr = %r/\A[-+]\d{4}/
          ct = sprintf("%s [%s-%02d] #timezoneoffset =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_empty cv,     sprintf("%s %s", ct, cv)
          assert_match cr, cv, sprintf("%s %s", ct, cv)

          # ---------------------------------------------------------------------------------------
          # TOKEN
          cv = rr.token
          cr = %r/\A[0-9a-f]{40}/
          ct = sprintf("%s [%s-%02d] #token =", ce, e, errorindex)

          assert_instance_of String, cv
          refute_empty cv,          sprintf("%s %s", ct, cv)
          assert_equal 40, cv.size, sprintf("%s %s", ct, cv)
          assert_match cr, cv,      sprintf("%s %s", ct, cv)

          # ---------------------------------------------------------------------------------------
          # DUMP(JSON)
          cv = rr.dump('json')
          ct = sprintf("%s [%s-%02d] #dump(json) =", ce, e, errorindex)
          cj = nil

          assert_instance_of String, cv
          refute_empty cv, sprintf("%s %s", ct, cv[0, 32])

          if RUBY_PLATFORM.start_with?('java')
            # java-based ruby environment like JRuby.
            begin
              require 'jrjackson'
              cj = JrJackson::Json.load(cv)
            rescue StandardError => je
              warn '***warning: Failed to JrJackson::Json.load: ' << je.to_s
            end
          else
            # MRI
            begin
              require 'oj'
              cj = Oj.load(cv, :mode => :compat)
            rescue StandardError => je
              warn '***warning: Failed to Oj.load: ' << je.to_s
            end
          end

          assert_instance_of Hash, cj
          assert_empty cj['catch'], sprintf("%s %s", ct, "")
          assert_equal cj['addresser'], rr.addresser.address, sprintf("%s %s", ct, cj['addresser'])
          assert_equal cj['recipient'], rr.recipient.address, sprintf("%s %s", ct, cj['recipient'])
          assert_equal cj['timestamp'], rr.timestamp.to_json, sprintf("%s %s", ct, cj['timestamp'])

          # ---------------------------------------------------------------------------------------
          # DUMP(YAML)
          cv = rr.dump('yaml')
          ct = sprintf("%s [%s-%02d] #dump(yaml) =", ce, e, errorindex)
          cy = nil

          assert_instance_of String, cv
          refute_empty cv, sprintf("%s %s", ct, cv[0, 32])

          require 'yaml'
          cy = YAML.load(cv)

          assert_instance_of Hash, cy
          assert_empty cy['catch'], sprintf("%s %s", ct, "")
          assert_equal cy['addresser'], rr.addresser.address, sprintf("%s %s", ct, cy['addresser'])
          assert_equal cy['recipient'], rr.recipient.address, sprintf("%s %s", ct, cy['recipient'])
          assert_equal cy['timestamp'], rr.timestamp.to_json, sprintf("%s %s", ct, cy['timestamp'])

          # ---------------------------------------------------------------------------------------
          # SOFTBOUNCE
          if false
            cv = rr.softbounce
            cr = %r/\A[-]?[01]\z/
            ct = sprintf("%s [%s-%02d] #softbounce =", ce, e, errorindex)

            assert_instance_of Integer, cv
            refute_empty cv.to_s,  sprintf("%s %s", ct, cv)
            if %w[delivered feedback vacation].include?(rr.reason)
              assert_equal -1, cv, sprintf("%s %s", ct, cv)
            else
              assert_equal  0, cv, sprintf("%s %s", ct, cv) if rr.hardbounce == true
              assert_equal  1, cv, sprintf("%s %s", ct, cv) if rr.hardbounce == false
            end
          end

        end # END OF Sisimai::Fact LIST
        emailindex += 1
        assert_equal true, errorindex > 0, sprintf("%s is including %d bounces", mailobject.data.path, errorindex)
      end # END OF Sisimai::Mail#read

    end
    assert_equal true, emailindex > 0, sprintf("%s have parsed %d emails", modulename, emailindex)

  end

end

