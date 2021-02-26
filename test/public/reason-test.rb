require 'minitest/autorun'
require 'sisimai/reason'
require 'sisimai'

class ReasonTest < Minitest::Test
  Methods = { class:  %w[get path retry index match] }
  Message = [
    'smtp; 550 5.1.1 <kijitora@example.co.jp>... User Unknown',
    'smtp; 550 Unknown user kijitora@example.jp',
    "smtp; 550 5.7.1 can't determine Purported ",
    'unknown; No such domain.',
    'SMTP; 550 5.2.1 The email account that you tried to reach is disabled. g0000000000ggg.00',
    'smtp; 550 Unknown user kijitora@example.co.jp',
    'smtp; 550 5.1.1 <kijitora@example.jp>... User unknown',
    'smtp; 550 5.1.1 <kijitora@example.or.jp>... User unknown',
    "x-unix; procmail: Couldn't create '/var/spool/mail/neko' id:",
    'smtp; 550 5.2.1 <filtered@example.co.jp>... User Unknown',
    'smtp; 550 5.1.1 <userunknown@example.co.jp>... User Unknown',
    'smtp; 550 Unknown user kijitora@example.net',
    'smtp; 550 5.1.1 Address rejected',
    'smtp; 450 4.1.1 <kijitora@example.org>: Recipient address',
    'X-Postfix; Host or domain name not found. Name service error',
    'X-mPOP-Fallback_MX; connect to example.com[93.184.216.119]:',
    'smtp; 452 4.3.2 Connection rate limit exceeded.',
    'smtp; 553 5.1.8 <root@vagrant-centos65.vagrantup.com>...',
    'smtp; 553 5.1.8 <root@vagrant-centos65.vagrantup.com>...',
    'smtp; 553 5.1.8 <root@vagrant-centos65.vagrantup.com>...',
    'smtp; 550 5.1.1 <userunknown@cubicroot.jp>... User Unknown',
    'smtp; 550 5.2.1 <kijitora@example.jp>... User Unknown',
    'smtp; 550 5.2.2 <noraneko@example.jp>... Mailbox Full',
    'X-Postfix; unknown user: "kijitora"',
    'X-Postfix; connect to',
    'smtp; 550 5.1.6 recipient no longer on server: kijitora@example.go.jp',
    'X-Postfix; Name service error for name=example.org',
    'smtp; 550 5.7.1 Unable to relay for relay_failed@testreceiver.com',
    'smtp; 550 Access from ip address 87.237.123.24 blocked. Visit',
    'SMTP; 550 5.1.1 <userunknown@bouncehammer.jp>... User Unknown',
    'smtp; 550 user unknown',
    'smtp; 426 connection timed out',
    'smtp;550 5.2.1 <kijitora@example.jp>... User Unknown',
    'smtp; 550 5.7.1 Message content rejected, UBE, id=00000-00-000',
    'x-unix; Quota exceeded message delivery failed to',
    '550 5.1.1 sid=i01K1n00l0kn1Em01 Address rejected foobar@foobar.com. [code=28] ',
    '554 imta14.emeryville.ca.mail.comcast.net comcast 192.254.113.140 Comcast block for spam.  Please see http://postmaster.comcast.net/smtp-error-codes.php#BL000000 ',
    'x-unix; Quota exceeded message delivery failed to',
    'X-Postfix; temporary failure. Command output: avpcheck: unable',
    'SMTP; 550 5.1.1 User unknown',
    'smtp; 550 5.1.1 <kijitora@example.jp>... User Unknown',
    'smtp; 550 5.2.1 <mikeneko@example.jp>... User Unknown',
    'smtp; 550 5.2.2 <sabineko@example.jp>... Mailbox Full',
    'X-Yandex; connect to 6jo.example.jp[192.0.2.79]:25:',
    'SMTP; 550 5.1.1 <userunknown@bouncehammer.jp>... User Unknown',
    'SMTP; 550 5.1.1 <userunknown@example.org>... User Unknown',
    'SMTP; 550 5.2.1 <filtered@example.com>... User Unknown',
    'SMTP; 550 5.1.1 <userunknown@example.co.jp>... User Unknown',
    'SMTP; 553 5.1.8 <httpd@host1.mx.example.jp>... Domain of sender',
    'SMTP; 552 5.2.3 Message size exceeds fixed maximum message size (10485760)',
    'SMTP; 550 5.6.9 improper use of 8-bit data in message header',
    'SMTP; 554 5.7.1 <kijitora@example.org>: Relay access denied',
    'SMTP; 450 4.7.1 Access denied. IP name lookup failed [192.0.2.222]',
    'SMTP; 554 5.7.9 Header error',
    'SMTP; 450 4.7.1 <c135.kyoto.example.ne.jp[192.0.2.56]>: Client host rejected: may not be mail exchanger',
    'X-Unix; 77',
    'SMTP; 554 IP=192.0.2.254 - A problem occurred. (Ask your postmaster for help or to contact neko@example.org to clarify.) (BL)',
    'SMTP; 551 not our user',
    'X-Unix; 255',
    'SMTP; 550 Unknown user kijitora@ntt.example.ne.jp',
    'SMTP; 554 5.4.6 Too many hops',
    'SMTP; 551 not our customer',
    'SMTP; 550-5.7.1 [180.211.214.199       7] Our system has detected that this message is',
    'SMTP; 550 Host unknown',
    'SMTP; 550 5.1.1 <=?utf-8?B?8J+QiPCfkIg=?=@example.org>... User unknown',
    'smtp; 550 kijitora@example.com... No such user',
    'smtp; 554 Service currently unavailable',
    'smtp; 554 Service currently unavailable',
    'smtp; 550 maria@dest.example.net... No such user',
    "smtp; 5.4.7 - Delivery expired (message too old) 'timeout' (delivery attempts: 0)",
    'X-Outbound-Mail-Relay; Host or domain name not found. Name',
    'smtp; 550 5.2.2 <kijitora@example.co.jp>... Mailbox Full',
    'smtp; 550 5.2.2 <sabineko@example.jp>... Mailbox Full',
    'smtp; 550 5.1.1 <mikeneko@example.jp>... User Unknown',
    'smtp; 550 5.1.1 <kijitora@example.co.jp>... User Unknown',
    'SMTP; 553 Invalid recipient destinaion@example.net (Mode: normal)',
    'smtp; 550 5.1.1 RCP-P2 http://postmaster.facebook.com/response_codes?ip=192.0.2.135#rcp Refused due to recipient preferences',
    'SMTP; 550 5.1.1 RCP-P1 http://postmaster.facebook.com/response_codes?ip=192.0.2.54#rcp ',
    'smtp;550 5.2.2 <kijitora@example.jp>... Mailbox Full',
    'smtp;550 5.1.1 <kijitora@example.jp>... User Unknown',
    'smtp;554 The mail could not be delivered to the recipient because the domain is not reachable. Please check the domain and try again (-1915321397:308:-2147467259)',
    'smtp;550 5.1.1 <sabineko@example.co.jp>... User Unknown',
    'smtp;550 5.2.2 <mikeneko@example.co.jp>... Mailbox Full',
    'smtp;550 Requested action not taken: mailbox unavailable (-2019901852:4030:-2147467259)',
    'smtp;550 5.1.1 <kijitora@example.or.jp>... User unknown',
    '550 5.1.1 <kijitora@example.jp>... User Unknown ',
    '550 5.1.1 <this-local-part-does-not-exist-on-the-server@example.jp>... ',
    'Connection timed out',
  ]

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Reason, e }
  end

  def test_get
    assert_nil Sisimai::Reason.get(nil)
    ce = assert_raises ArgumentError do
      Sisimai::Reason.get()
      Sisimai::Reason.get(nil, nil)
    end
  end

  def test_path
    cv = Sisimai::Reason.path
    assert_instance_of Hash, cv

    cv.each_key do |e|
      assert_match %r|\ASisimai::Reason::|, e
      assert_match %r|\Asisimai/reason/.+|, cv[e]
    end

    ce = assert_raises ArgumentError do
      Sisimai::Reason.path(nil)
      Sisimai::Reason.path(nil, nil)
    end
  end

  def test_retry
    cv = Sisimai::Reason.retry
    assert_instance_of Hash, cv

    cv.each_key do |e|
      assert_match %r|\A[a-z]+\z|, e
      assert_equal true, cv[e]
    end

    ce = assert_raises ArgumentError do
      Sisimai::Reason.retry(nil)
      Sisimai::Reason.retry(nil, nil)
    end
  end

  def test_index
    cv = Sisimai::Reason.index
    assert_instance_of Array, cv
    refute_empty cv

    cv.each do |e|
      assert_match %r|\A[A-Za-z]+\z|, e
    end

    ce = assert_raises ArgumentError do
      Sisimai::Reason.index(nil)
      Sisimai::Reason.index(nil, nil)
    end
  end

  def test_match
    cv = Sisimai.reason.keys.map { |e| e.to_s.downcase }
    Message.each do |e|
      ca = Sisimai::Reason.match(e)
      cb = Sisimai.match(e)

      assert_instance_of String, ca
      assert_instance_of String, cb
      assert_equal true, cv.include?(ca)
      assert_equal true, cv.include?(cb)
      assert_equal ca, cb
    end
  end


end

