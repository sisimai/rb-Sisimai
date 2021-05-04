require 'minitest/autorun'
require 'sisimai/mail'

class MailTest < Minitest::Test
  Methods = { class: %w[new], object: %w[path kind data] }
  Samples = ['./set-of-emails/mailbox/mbox-0', './set-of-emails/maildir/err']
  Normals = './set-of-emails/maildir/not'

  Mailbox = Sisimai::Mail.new(Samples[0])
  Maildir = Sisimai::Mail.new(Samples[1])
  StandardIn = Sisimai::Mail.new(STDIN)
  f = File.open(Samples[0], "r")
  v = f.read; f.close
  MailString = Sisimai::Mail.new(v)
  IsntBounce = Sisimai::Mail.new(Normals)

  def test_methods
    Methods[:class].each  { |e| assert_respond_to Sisimai::Mail, e }
    Methods[:object].each do |e|
      assert_respond_to Mailbox, e
      assert_respond_to Maildir, e
      assert_respond_to StandardIn, e
      assert_respond_to MailString, e
      assert_respond_to IsntBounce, e
    end
  end

  def test_new
    assert_instance_of Sisimai::Mail, Mailbox
    assert_instance_of Sisimai::Mail, Maildir
    assert_instance_of Sisimai::Mail, StandardIn
    assert_instance_of Sisimai::Mail, MailString
    assert_instance_of Sisimai::Mail, IsntBounce

    ce = assert_raises ArgumentError do
      Sisimai::Mail.new()
      Sisimai::Mail.new(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_path
    assert_instance_of String, Mailbox.path
    assert_instance_of String, Maildir.path
    assert_instance_of String, StandardIn.path
    assert_instance_of String, MailString.path
    assert_instance_of String, IsntBounce.path

    assert_equal Samples[0], Mailbox.path
    assert_equal Samples[1], Maildir.path
    assert_equal '<STDIN>',  StandardIn.path
    assert_equal 'MEMORY',   MailString.path
    assert_equal Normals,    IsntBounce.path

    ce = assert_raises ArgumentError do
      Mailbox.path(nil)
      Maildir.path(nil)
      StandardIn.path(nil)
      MailString.path(nil)
      IsntBounce.path(nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_kind
    assert_instance_of String, Mailbox.kind
    assert_instance_of String, Maildir.kind
    assert_instance_of String, StandardIn.kind
    assert_instance_of String, MailString.kind
    assert_instance_of String, IsntBounce.kind

    assert_equal 'mailbox', Mailbox.kind
    assert_equal 'maildir', Maildir.kind
    assert_equal 'stdin',   StandardIn.kind
    assert_equal 'memory',  MailString.kind
    assert_equal 'maildir', IsntBounce.kind

    ce = assert_raises ArgumentError do
      Mailbox.kind(nil)
      Maildir.kind(nil)
      StandardIn.kind(nil)
      MailString.kind(nil)
      IsntBounce.kind(nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_data
    assert_instance_of Sisimai::Mail::Mbox,    Mailbox.data
    assert_instance_of Sisimai::Mail::Maildir, Maildir.data
    assert_instance_of Sisimai::Mail::STDIN,   StandardIn.data
    assert_instance_of Sisimai::Mail::Memory,  MailString.data
    assert_instance_of Sisimai::Mail::Maildir, IsntBounce.data

    ce = assert_raises ArgumentError do
      Mailbox.data(nil)
      Maildir.data(nil)
      StandardIn.data(nil)
      MailString.data(nil)
      IsntBounce.data(nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_dataread
    ci = 0
    while r = Mailbox.data.read do
      ci += 1
      assert_instance_of String, r
      refute_empty r
    end
    assert_equal 37, ci

    ci = 0
    while r = Maildir.data.read do
      ci += 1
      assert_instance_of String, r
      refute_empty r
    end
    assert_equal 37, ci

    ci = 0
    while r = MailString.data.read do
      ci += 1
      assert_instance_of String, r
      refute_empty r
    end
    assert_equal 37, ci

    ci = 0
    while r = IsntBounce.data.read do
      ci += 1
      assert_instance_of String, r
      refute_empty r
    end
    assert_equal 2, ci
  end

end
