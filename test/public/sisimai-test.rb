require 'minitest/autorun'
require 'sisimai'
require 'json'

class SisimaiTest < Minitest::Test
  Methods = { class: %w[version libname rise dump engine reason match make] }
  Samples = {
    mailbox: './set-of-emails/mailbox/mbox-0',
    maildir: './set-of-emails/maildir/bsd',
    memory:  './set-of-emails/mailbox/mbox-1',
  }
  Normals = {
    maildir: './set-of-emails/maildir/not'
  }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai, e }
  end

  def test_libname
    assert_equal 'Sisimai', Sisimai.libname
  end

  def test_version
    assert_match %r/\A5[.]\d+[.]\d+/, Sisimai.version
    assert_match %r/\A5[.]\d+[.]\d+/, Sisimai::VERSION
  end

  def test_rise
    ce = assert_raises ArgumentError do
      Sisimai.rise()
      Sisimai.rise('/path/to/email', 1)
    end
    assert_match %r/wrong number of arguments/, ce.to_s
    assert_nil Sisimai.rise(nil)
    assert_nil Sisimai.rise(false)

    Samples.keys.each do |e|
      cf = Samples[e]
      cr = nil

      if e.to_s == 'memory'
        # :memory
        ch = File.open(cf, "r")
        cc = ch.read; ch.close
        cr = Sisimai.rise(cc)
      else
        # :mailbox, or :maildir
        cr = Sisimai.rise(cf)
      end

      assert_instance_of Array, cr
      refute_empty cr

      cr.each do |ee|
        assert_instance_of Sisimai::Fact,    ee
        assert_instance_of Sisimai::Time,    ee.timestamp
        assert_instance_of Sisimai::Address, ee.recipient
        assert_instance_of Sisimai::Address, ee.recipient

        assert_respond_to ee, 'softbounce'
        assert_respond_to ee, 'damn'

        refute_empty ee.addresser.address
        refute_empty ee.recipient.address
        refute_empty ee.reason
        refute_nil   ee.replycode
        refute_empty ee.token

        cv = ee.damn
        assert_instance_of Hash, cv
        refute_empty cv
        assert_equal ee.addresser.address,      cv['addresser']
        assert_equal ee.recipient.address,      cv['recipient']
        assert_equal ee.timestamp.to_time.to_i, cv['timestamp']

        cv.each_key do |eee|
          next if ee.send(eee).class.to_s.start_with?('Sisimai::')
          next if eee == 'subject'

          if eee == 'catch'
            assert_empty cv['catch']
          else
            assert_equal ee.send(eee.to_sym), cv[eee], 'Sisimai::Fact.' << eee
          end
        end

        refute_empty ee.dump('json')
      end

      mesghook = lambda do |argv|
        data = {
          'x-mailer'        => '?',
          'return-path'     => '?',
          'x-virus-scanned' => '?',
        }
        if cv = argv['message'].match(/^X-Mailer:\s*(.+)$/)
            data['x-mailer'] = cv[1]
        end

        if cv = argv['message'].match(/^Return-Path:\s*(.+)$/)
            data['return-path'] = cv[1]
        end
        data['from'] = argv['headers']['from'] || 'Postmaster'
        data['from'] = 'Postmaster' if data['from'].empty?
        data['x-virus-scanned'] = argv['headers']['x-virus-scanned'] || '?'

        return data
      end

      filehook = lambda do |argv|
        timep = ::Time.new
        index = 0
        argv['fact'].each do |p|
          index += 1
          p.catch['parsedat'] = timep.localtime.to_s
          p.catch['index']    = index
          p.catch['kind']     = argv['kind'].capitalize
          p.catch['size']     = File.size(argv['path'])
        end
      end

      cr = Sisimai.rise(cf, c___: [mesghook, filehook])
      assert_instance_of Array, cr
      refute_empty cr

      cr.each do |ee|
        assert_instance_of Sisimai::Fact, ee
        assert_instance_of Hash, ee.catch

        refute_empty ee.catch['x-mailer']
        assert_match %r/[A-Z?]/, ee.catch['x-mailer']

        refute_empty ee.catch['return-path']
        assert_match %r/(?:<>|.+[@].+|mailer-daemon|[?])/i, ee.catch['return-path']

        refute_empty ee.catch['from']
        assert_match %r/(?:<>|.+[@].+|mailer-daemon|postmaster)/i, ee.catch['from']

        refute_empty ee.catch['x-virus-scanned']
        assert_match %r/(?:amavis|clam|[?])/i, ee.catch['x-virus-scanned']

        assert ee.catch['size'] > 0
        assert ee.catch['index'] > 0
        assert_match %r/\A\d{4}-\d{2}-\d{2}/, ee.catch['parsedat']
        assert_match %r/\AMail(?:box|dir)\z/, ee.catch['kind']
      end

      cr = Sisimai.rise(cf, c___: [])
      assert_instance_of Array, cr
      refute_empty cr
      cr.each { |ee| assert_nil ee.catch }
    end
  end

  def test_make
    # For the backward compatible
    ce = assert_raises ArgumentError do
      Sisimai.make()
      Sisimai.make('/path/to/email', 1)
    end
    assert_match %r/wrong number of arguments/, ce.to_s
    assert_nil Sisimai.make(nil)
    assert_nil Sisimai.make(false)
  end

  def test_dump
    ce = assert_raises ArgumentError do
      Sisimai.dump()
      Sisimai.dump('/path/to/email', 1)
    end
    assert_match %r/wrong number of arguments/, ce.to_s
    assert_nil Sisimai.dump(nil)
    assert_nil Sisimai.dump(false)

    Samples.each_key do |e|
      cf = Samples[e]
      cj = Sisimai.dump(cf)
      cr = JSON.parse(cj)

      assert_instance_of ::String, cj
      assert_instance_of ::Array,  cr
      refute_empty cj
      refute_empty cr

      cr.each do |ee|
        assert_instance_of ::Hash, ee
        assert_instance_of ::String, ee['addresser']
        assert_instance_of ::String, ee['recipient']

        %w[addresser recipient destination reason timestamp token smtpagent origin].each do |eee|
          assert ee[eee]
        end
      end
    end
  end

  def test_normal
    Normals.keys.each do |e|
      cf = Normals[e]
      assert_nil Sisimai.rise(cf)
      assert_equal '[]', Sisimai.dump(cf)
    end
  end

  def test_engine
    cv = Sisimai.engine
    assert_instance_of Hash, cv
    refute_empty cv
    cv.keys.each do |e|
      assert_match /\ASisimai::/, e
      assert_instance_of ::String, cv[e]
    end
  end

  def test_reason
    cv = Sisimai.reason
    assert_instance_of Hash, cv
    refute_empty cv
    cv.keys.each do |e|
      assert_match /\A[A-Z]/, e
      assert_instance_of ::String, cv[e]
    end
  end

end

