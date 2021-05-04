require 'minitest/autorun'
require 'sisimai/mail/maildir'

class MailMaildirTest < Minitest::Test
  Methods = { class: %w[new], object: %w[path dir file size handle offset read] }
  Samples = ['./set-of-emails/maildir/bsd', './set-of-emails/maildir/mac']
  Maildir = Sisimai::Mail::Maildir.new(Samples[0])
  DirSize = 503

  def test_methods
    Methods[:class].each  { |e| assert_respond_to Sisimai::Mail::Maildir, e }
    Methods[:object].each { |e| assert_respond_to Maildir, e }
  end

  def test_new
    assert_instance_of Sisimai::Mail::Maildir, Sisimai::Mail::Maildir.new(Samples[0])
    assert_instance_of Sisimai::Mail::Maildir, Sisimai::Mail::Maildir.new(Samples[1])

    ce = assert_raises ArgumentError do
      Sisimai::Mail::Maildir.new()
      Sisimai::Mail::Maildir.new(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_path
    ce = assert_raises ArgumentError do
      Maildir.path(nil)
      Maildir.path(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_dir
    assert_instance_of String, Maildir.dir
    refute_empty Maildir.dir
    assert_equal Samples[0], Maildir.dir

    ce = assert_raises ArgumentError do
      Maildir.dir(nil)
      Maildir.dir(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_file
    ce = assert_raises ArgumentError do
      Maildir.file(nil)
      Maildir.file(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_size
    assert_instance_of Integer, Maildir.size
    assert_equal true, Maildir.size > 0
    assert_equal 505, Maildir.size

    ce = assert_raises ArgumentError do
      Maildir.size(nil)
      Maildir.size(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_handle
    assert_instance_of Dir, Maildir.handle

    ce = assert_raises ArgumentError do
      Maildir.handle(nil)
      Maildir.handle(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_offset
    assert_instance_of Integer, Maildir.offset
    assert_equal true, Maildir.offset >= 0
    assert_equal true, Maildir.offset <= 96906

    ce = assert_raises ArgumentError do
      Maildir.offset(nil)
      Maildir.offset(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_read
    ci = 0
    while r = Maildir.read do
      ci += 1
      assert_instance_of String, r
      assert_instance_of String, Maildir.path
      assert_instance_of String, Maildir.file
      assert_match   /[.]eml\z/, Maildir.file
      refute_empty r
      assert_equal true, Maildir.offset > 1
    end
    assert_equal true, ci > 0
    assert_equal true, Maildir.offset > 0
  end

end

