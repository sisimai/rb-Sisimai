require 'minitest/autorun'
require 'sisimai/mail/mbox'

class MailMboxTest < Minitest::Test
  Methods = { class: %w[new], object: %w[path dir file size handle offset read] }
  Samples = ['./set-of-emails/mailbox/mbox-0', './set-of-emails/mailbox/mbox-1']
  Mailbox = Sisimai::Mail::Mbox.new(Samples[0])

  def test_methods
    Methods[:class].each  { |e| assert_respond_to Sisimai::Mail::Mbox, e }
    Methods[:object].each { |e| assert_respond_to Mailbox, e }
  end

  def test_new
    assert_instance_of Sisimai::Mail::Mbox, Sisimai::Mail::Mbox.new(Samples[0])
    assert_instance_of Sisimai::Mail::Mbox, Sisimai::Mail::Mbox.new(Samples[1])

    ce = assert_raises ArgumentError do
      Sisimai::Mail::Mbox.new()
      Sisimai::Mail::Mbox.new(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_path
    assert_instance_of String, Mailbox.path
    refute_empty Mailbox.path
    assert_equal Samples[0], Mailbox.path

    ce = assert_raises ArgumentError do
      Mailbox.path(nil)
      Mailbox.path(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_dir
    assert_instance_of String, Mailbox.dir
    refute_empty Mailbox.dir
    assert_equal File.dirname(Samples[0]), Mailbox.dir

    ce = assert_raises ArgumentError do
      Mailbox.dir(nil)
      Mailbox.dir(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_file
    assert_instance_of String, Mailbox.file
    refute_empty Mailbox.file
    assert_equal File.basename(Samples[0]), Mailbox.file

    ce = assert_raises ArgumentError do
      Mailbox.file(nil)
      Mailbox.file(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_size
    assert_instance_of Integer, Mailbox.size
    assert_equal  true, Mailbox.size > 0
    assert_equal 96906, Mailbox.size

    ce = assert_raises ArgumentError do
      Mailbox.size(nil)
      Mailbox.size(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_handle
    assert_instance_of File, Mailbox.handle

    ce = assert_raises ArgumentError do
      Mailbox.handle(nil)
      Mailbox.handle(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_offset
    assert_instance_of Integer, Mailbox.offset
    assert_equal true, Mailbox.offset >= 0
    assert_equal true, Mailbox.offset <= 96906

    ce = assert_raises ArgumentError do
      Mailbox.offset(nil)
      Mailbox.offset(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_read
    ci = 0
    while r = Mailbox.read do
      ci += 1
      assert_instance_of String, r
      refute_empty r
      assert_equal true, Mailbox.offset > 1
    end
    assert_equal 37, ci
    assert_equal File.size(Samples[0]), Mailbox.offset
  end

end

