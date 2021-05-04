require 'minitest/autorun'
require 'sisimai/rfc1894'

class RFC1894Test < Minitest::Test
  Methods = { class: %w[FIELDTABLE field match] }

  Field01 = [
    'Reporting-MTA: dns; neko.example.jp',
    'Received-From-MTA: dns; mx.libsisimai.org',
    'Arrival-Date: Sun, 3 Jun 2018 14:22:02 +0900 (JST)',
  ]
  Field02 = [
    'Final-Recipient: RFC822; kijitora@neko.example.jp',
    'X-Actual-Recipient: RFC822; sironeko@nyaan.jp',
    'Original-Recipient: RFC822; kuroneko@libsisimai.org',
    'Action: failed',
    'Status: 4.4.7',
    'Remote-MTA: DNS; [127.0.0.1]',
    'Last-Attempt-Date: Sat, 9 Jun 2018 03:06:57 +0900 (JST)',
    'Diagnostic-Code: SMTP; Unknown user neko@nyaan.jp',
  ]
  Field99 = [
    'Content-Type: message/delivery-status',
    'Subject: Returned mail: see transcript for details',
    'From: Mail Delivery Subsystem <MAILER-DAEMON@neko.example.jp>',
    'Date: Sat, 9 Jun 2018 03:06:57 +0900 (JST)',
  ]

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::RFC1894, e }
  end

  def test_FIELDTABLE
    cv = Sisimai::RFC1894.FIELDTABLE
    assert_instance_of Hash, cv
    refute_empty cv

    ce = assert_raises ArgumentError do
      Sisimai::RFC1894.FIELDTABLE(nil)
    end
  end

  def test_match
    Field01.each { |e| assert_equal 1, Sisimai::RFC1894.match(e) }
    Field02.each { |e| assert_equal 2, Sisimai::RFC1894.match(e) }
    Field99.each { |e| assert_nil      Sisimai::RFC1894.match(e) }

    ce = assert_raises ArgumentError do
      Sisimai::RFC1894.match(nil, nil)
    end
  end

  def test_field
    Field01.each do |e|
      cv = Sisimai::RFC1894.field(e)
      assert_instance_of Array, cv

      if cv[3] == 'host'
        assert_equal 'DNS', cv[1]
        assert_match /[.]/, cv[2]
      else
        assert_equal '',    cv[1]
      end
      assert_match /(?:host|date)/, cv[3]
    end

    Field02.each do |e|
      cv = Sisimai::RFC1894.field(e)
      assert_instance_of Array, cv

      if cv[3] =~ /(?:host|addr|code)/
        assert_match /(?:DNS|RFC822|SMTP)/, cv[1]
        assert_match /[.]/,                 cv[2]
      else
        assert_equal '',    cv[1]
      end
      assert_match /(?:host|date|addr|list|stat|code)/, cv[3]
    end

    Field99.each { |e| assert_nil Sisimai::RFC1894.field(e) }

    ce = assert_raises ArgumentError do
      Sisimai::RFC1894.field()
      Sisimai::RFC1894.field(nil, nil)
    end
  end

end
