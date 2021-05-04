require 'minitest/autorun'
require 'sisimai/datetime'
require 'time'

class DateTimeTest < Minitest::Test
  Methods = { class: %w[to_second monthname dayofweek parse abbr2tz tz2second second2tz] }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::DateTime, e }
  end

  def test_to_second
    assert_equal 86400, Sisimai::DateTime.to_second('1d')
    assert_equal 86400 * 7 * 2, Sisimai::DateTime.to_second('2w')
    assert_equal 86400 * 14 * 3, Sisimai::DateTime.to_second('3f').to_i
    assert_equal 10205771, Sisimai::DateTime.to_second('4l').to_i
    assert_equal 39446190, Sisimai::DateTime.to_second('5q')
    assert_equal 189341712, Sisimai::DateTime.to_second('6y')
    assert_equal 883594656, Sisimai::DateTime.to_second('7o')
    assert_equal 23, Sisimai::DateTime.to_second('gs').to_i
    assert_equal 188, Sisimai::DateTime.to_second('pm').to_i
    assert_equal 9785, Sisimai::DateTime.to_second('eh').to_i
    assert_equal 0, Sisimai::DateTime.to_second(-1)
    assert_equal 0, Sisimai::DateTime.to_second(-4294967296)
    assert_equal 0, Sisimai::DateTime.to_second(nil)
    assert_equal 0, Sisimai::DateTime.to_second(false)
    assert_equal 0, Sisimai::DateTime.to_second('')
    assert_equal 0, Sisimai::DateTime.to_second(22)

    ce = assert_raises ArgumentError do
      Sisimai::DateTime.to_second()
      Sisimai::DateTime.to_second(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_monthname
    cv = Sisimai::DateTime.monthname(false)
    assert_instance_of Array, cv
    assert_equal 'Jan', cv[0]
    assert_equal 'Oct', cv[9]

    cv = Sisimai::DateTime.monthname(true)
    assert_instance_of Array, cv
    assert_equal 'February', cv[1]
    assert_equal 'September', cv[8]

    ce = assert_raises ArgumentError do
      Sisimai::DateTime.monthname(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_dayofweek
    cv = Sisimai::DateTime.dayofweek(false)
    assert_instance_of Array, cv
    assert_equal 'Mon', cv[1]
    assert_equal 'Fri', cv[5]

    cv = Sisimai::DateTime.dayofweek(true)
    assert_instance_of Array, cv
    assert_equal 'Tuesday', cv[2]
    assert_equal 'Thursday', cv[4]

    ce = assert_raises ArgumentError do
      Sisimai::DateTime.dayofweek(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  DateStrings = [
    'Mon, 2 Apr 2001 04:01:03 +0900 (JST)',
    'Fri, 9 Apr 2004 04:01:03 +0000 (GMT)',
    'Thu, 5 Apr 2007 04:01:03 -0000 (UTC)',
    'Thu, 03 Mar 2010 12:46:23 +0900',
    'Thu, 17 Jun 2010 01:43:33 +0900',
    'Thu, 1 Apr 2010 20:51:58 +0900',
    'Thu, 01 Apr 2010 16:25:40 +0900',
    '27 Apr 2009 08:08:54 +0000',
    'Fri,18 Oct 2002 16:03:06 PM',
    '27 Sep 1998 00:51:27 -0400',
    'Sat, 21 Nov 1998 16:38:02 -0500 (EST)',
    'Sat, 21 Nov 1998 13:13:04 -0800 (PST)',
    '    Sat, 21 Nov 1998 15:40:24 -0600',
    'Thu, 19 Nov 98 06:53:46 +0100',
    '03 Apr 1998 09:59:35 +0200',
    '19 Mar 1998 20:55:10 +0100',
    '2010-06-18 17:17:52 +0900',
    '2010-06-18T17:17:52 +0900',
    'Foo, 03 Mar 2010 12:46:23 +0900',
    'Thu, 13 Mar 100 12:46:23 +0900',
    'Thu, 03 Mar 2001 12:46:23 -9900',
    'Thu, 03 Mar 2001 12:46:23 +9900',
    'Sat, 21 Nov 1998 13:13:04 -0800 (PST)    ',
    'Sat, 21 Nov 1998 13:13:04 -0800 (PST) JST',
    'Sat, 21 Nov 1998 13:13:04 -0800 (PST) Hoge',
    'Fri, 29 Apr 2013 02:31 +0900',
    'Sun, 29 Apr 2014 1:2:3 +0900',
    'Sun, 29 May 2014 1:2 +0900',
    '4/29/01 11:34:45 PM',
    '2014-03-26 00-01-19',
  ]
  InvalidDate = [
    'Thu, 13 Cat 2000 22:22:22 +2222',
    'Thu, 17 Apr 1192 12:46:23 +0900',
    'Thu, 19 May 2600 14:51:10 +0900',
    'Thu, 22 Jun 2001 32:40:29 +0900',
    'Thu, 25 Jul 1995 00:86:00 +0900',
    'Thu, 31 Aug 2013 11:22:73 +0900',
    'Thu, 36 Sep 2009 11:22:33 +0900',
  ]
  def test_parse
    DateStrings.each do |e|
      cv = Sisimai::DateTime.parse(e).sub(/[-+]\d{4}\z/, '')
      ct = Time.strptime(cv, "%a, %d %b %Y %T")

      assert_instance_of String, cv
      assert_instance_of   Time, ct

      refute_empty cv
      assert_equal true, ct.year > 1900
    end

    InvalidDate.each do |e|
      assert_nil Sisimai::DateTime.parse(e)
    end

    ce = assert_raises ArgumentError do
      Sisimai::DateTime.parse()
      Sisimai::DateTime.parse(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
    assert_nil Sisimai::DateTime.parse(nil)
    assert_nil Sisimai::DateTime.parse('')
  end

  def test_abbr2tz
    assert_equal '+0000', Sisimai::DateTime.abbr2tz('GMT')
    assert_equal '-0000', Sisimai::DateTime.abbr2tz('UTC')
    assert_equal '+0900', Sisimai::DateTime.abbr2tz('JST')
    assert_equal '-0700', Sisimai::DateTime.abbr2tz('PDT')
    assert_equal '-0700', Sisimai::DateTime.abbr2tz('MST')
    assert_equal '-0500', Sisimai::DateTime.abbr2tz('CDT')
    assert_equal '-0400', Sisimai::DateTime.abbr2tz('EDT')
    assert_equal '-1000', Sisimai::DateTime.abbr2tz('HST')
    assert_equal '-0000', Sisimai::DateTime.abbr2tz('UT')

    ce = assert_raises ArgumentError do
      Sisimai::DateTime.abbr2tz()
      Sisimai::DateTime.abbr2tz(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
    assert_nil Sisimai::DateTime.abbr2tz('NEKO')
    assert_nil Sisimai::DateTime.abbr2tz('NYAN')
  end

  def test_tz2second
    assert_equal      0, Sisimai::DateTime.tz2second('+0000')
    assert_equal      0, Sisimai::DateTime.tz2second('-0000')
    assert_equal  32400, Sisimai::DateTime.tz2second('+0900')
    assert_equal -32400, Sisimai::DateTime.tz2second('-0900')
    assert_equal  43200, Sisimai::DateTime.tz2second('+1200')
    assert_equal -43200, Sisimai::DateTime.tz2second('-1200')
    assert_nil           Sisimai::DateTime.tz2second('+1800')
    assert_nil           Sisimai::DateTime.tz2second('-1800')
    assert_nil           Sisimai::DateTime.tz2second('NYAAN')

    ce = assert_raises ArgumentError do
      Sisimai::DateTime.tz2second()
      Sisimai::DateTime.tz2second(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_second2tz
    assert_equal '+0000', Sisimai::DateTime.second2tz(0)
    assert_equal '+0900', Sisimai::DateTime.second2tz(32400)
    assert_equal '-0900', Sisimai::DateTime.second2tz(-32400)
    assert_equal '+1200', Sisimai::DateTime.second2tz(43200)
    assert_equal '-1200', Sisimai::DateTime.second2tz(-43200)

    ce = assert_raises ArgumentError do
      Sisimai::DateTime.second2tz()
      Sisimai::DateTime.second2tz(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
    assert_equal '+0000', Sisimai::DateTime.second2tz('neko')
    assert_equal '+0000', Sisimai::DateTime.second2tz('')
    assert_equal '+0000', Sisimai::DateTime.second2tz(nil)
    assert_nil            Sisimai::DateTime.second2tz(65535)
    assert_nil            Sisimai::DateTime.second2tz(-65535)
  end
end
