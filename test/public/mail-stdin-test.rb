require 'minitest/autorun'
require 'sisimai/mail/stdin'

class MailStdinTest < Minitest::Test
  Methods = { class: %w[new], object: %w[path size handle offset read] }
  Device1 = Sisimai::Mail::STDIN.new(STDIN)

  def test_methods
    Methods[:class].each  { |e| assert_respond_to Sisimai::Mail::STDIN, e }
    Methods[:object].each { |e| assert_respond_to Device1, e }
    Device1.handle.close
  end

  def test_new
    assert_instance_of Sisimai::Mail::STDIN, Sisimai::Mail::STDIN.new(STDIN)

    ce = assert_raises ArgumentError do
      Sisimai::Mail::STDIN.new()
      Sisimai::Mail::STDIN.new(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_path
    ce = assert_raises ArgumentError do
      Device1.path(nil)
      Device1.path(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_size
    assert_nil Device1.size

    ce = assert_raises ArgumentError do
      Device1.size(nil)
      Device1.size(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_offset
    assert_instance_of Integer, Device1.offset
    assert_equal true, Device1.offset >= 0
    assert_equal true, Device1.offset <= 96906

    ce = assert_raises ArgumentError do
      Device1.offset(nil)
      Device1.offset(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_handle
    assert_instance_of IO, Device1.handle

    ce = assert_raises ArgumentError do
      Device1.handle(nil)
      Device1.handle(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end


end

