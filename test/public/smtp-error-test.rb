require 'minitest/autorun'
require 'sisimai/smtp/error'

class SMTPError < Minitest::Test
  Methods = { class: %w[find] }
  Bounces = {
    soft: [
      'blocked', 'contenterror', 'exceedlimit', 'expired', 'filtered', 'mailboxfull', 'mailererror',
      'mesgtoobig', 'networkerror', 'norelaying', 'rejected', 'securityerror', 'spamdetected',
      'suspend', 'systemerror', 'systemfull', 'toomanyconn', 'undefined', 'onhold',
    ],
    hard: ['userunknown', 'hostunknown', 'hasmoved', 'notaccept'],
  }
  NoError = ['delivered', 'feedback', 'vacation']
  WasSent = ['smtp; 2.1.5 250 OK']
  TempErr = ['smtp; 450 4.0.0 Temporary failure']
  PermErr = [
    'smtp;550 5.2.2 <mikeneko@example.co.jp>... Mailbox Full',
    'smtp; 550 5.1.1 Mailbox does not exist',
    'smtp; 550 5.1.1 Mailbox does not exist',
    'smtp; 552 5.2.2 Mailbox full',
    'smtp; 552 5.3.4 Message too large',
    'smtp; 500 5.6.1 Message content rejected',
    'smtp; 550 5.2.0 Message Filtered',
    '550 5.1.1 <kijitora@example.jp>... User Unknown',
    'SMTP; 552-5.7.0 This message was blocked because its content presents a potential',
    'SMTP; 550 5.1.1 Requested action not taken: mailbox unavailable',
    'SMTP; 550 5.7.1 IP address blacklisted by recipient',
  ]

  def test_is_permanent
    WasSent.each { |e| assert_nil          Sisimai::SMTP::Error.is_permanent(e) }
    TempErr.each { |e| assert_equal false, Sisimai::SMTP::Error.is_permanent(e) }
    PermErr.each { |e| assert_equal true,  Sisimai::SMTP::Error.is_permanent(e) }

    ce = assert_raises ArgumentError do
      Sisimai::SMTP::Error.is_permanent()
      Sisimai::SMTP::Error.is_permanent(nil, nil)
    end
    assert_nil Sisimai::SMTP::Error.is_permanent(nil)
  end

  def test_soft_or_hard
    Bounces[:soft].each { |e| assert_equal 'soft', Sisimai::SMTP::Error.soft_or_hard(e) }
    Bounces[:hard].each do |e|
      assert_equal 'hard', Sisimai::SMTP::Error.soft_or_hard(e)
      assert_equal 'hard', Sisimai::SMTP::Error.soft_or_hard(e, '503 Not accept any email') if e == 'notaccept'
      assert_equal 'soft', Sisimai::SMTP::Error.soft_or_hard(e, '409 Not accept any email') if e == 'notaccept'
    end
    NoError.each { |e| assert_equal '', Sisimai::SMTP::Error.soft_or_hard(e) }

    ce = assert_raises ArgumentError do
      Sisimai::SMTP::Error.soft_or_hard()
      Sisimai::SMTP::Error.soft_or_hard(nil, nil, nil)
    end
    assert_nil Sisimai::SMTP::Error.soft_or_hard(nil)
  end

end
