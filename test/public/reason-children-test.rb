require 'minitest/autorun'
require 'sisimai/reason'
require 'sisimai'

class ReasonChildrenTest < Minitest::Test
  Reasons = {
    'Blocked'         => ['550 Access from ip address 192.0.2.1 blocked.'],
    'ContentError'    => ['550 5.6.0 the headers in this message contain improperly-formatted binary content'],
    'ExceedLimit'     => ['5.2.3 Message too large'],
    'Expired'         => ['421 4.4.7 Delivery time expired'],
    'Filtered'        => ['550 5.1.2 User reject'],
    'HasMoved'        => ['550 5.1.6 address neko@cat.cat has been replaced by neko@example.jp'],
    'HostUnknown'     => ['550 5.2.1 Host Unknown'],
    'MailboxFull'     => ['450 4.2.2 Mailbox full'],
    'MailerError'     => ['X-Unix; 255'],
    'MesgTooBig'      => ['400 4.2.3 Message too big'],
    'NetworkError'    => ['554 5.4.6 Too many hops'],
    'NoRelaying'      => ['550 5.0.0 Relaying Denied'],
    'NotAccept'       => ['556 SMTP protocol returned a permanent error'],
    'OnHold'          => ['5.0.901 error'],
    'Rejected'        => ['550 5.1.8 Domain of sender address example.org does not exist'],
    'PolicyViolation' => ['570 5.7.7 Email not accepted for policy reasons'],
    'SecurityError'   => ['570 5.7.0 Authentication failure'],
    'SpamDetected'    => ['570 5.7.7 Spam Detected'],
    'Suspend'         => ['550 5.0.0 Recipient suspend the service'],
    'SystemError'     => ['500 5.3.5 System config error'],
    'SystemFull'      => ['550 5.0.0 Mail system full'],
    'TooManyConn'     => ['421 Too many connections'],
    'UserUnknown'     => ['550 5.1.1 Unknown User'],
    'VirusDetected'   => ['550 5.7.9 The message was rejected because it contains prohibited virus or spam content'],
  }

  def test_reason
    cv = Sisimai.rise('./set-of-emails/maildir/bsd/lhost-sendmail-01.eml').shift
    cw = cv.damn
    assert_instance_of Sisimai::Fact, cv
    assert_instance_of Hash, cw

    Reasons.each_key do |e|
      cr = 'Sisimai::Reason::' << e
      require cr.downcase.gsub('::', '/')
      cx = Module.const_get(cr)

      assert_equal Module, cx.class
      assert_equal e.downcase, cx.text;
      refute_empty cx.description
      assert_includes [true, false, nil], cx.true(cw)

      next if e == 'OnHold'
      Reasons[e].each do |ee|
        assert_equal true, cx.match(ee.downcase)
      end

      ce = assert_raises ArgumentError do
        cx.text(nil)
        cx.true()
        cx.match()
        cx.description(nil)
      end
    end

    %w[Delivered Feedback Undefined Vacation SyntaxError].each do |e|
      cr = 'Sisimai::Reason::' << e
      require cr.downcase.gsub('::', '/')
      cx = Module.const_get(cr)

      assert_equal Module, cx.class
      assert_equal e.downcase, cx.text;
      refute_empty cx.description
      assert_includes [false, nil], cx.true(cw)
    end


  end

end

