require 'minitest/autorun'
require 'sisimai/mail/memory'

class MailMemoryTest < Minitest::Test
  Methods = { class: %w[new], object: %w[path size offset payload read] }
  Samples = ['./set-of-emails/mailbox/mbox-0', './set-of-emails/maildir/bsd/lhost-sendmail-01.eml']

  ch = File.open(Samples[0], 'r'); Cv1 = ch.read; ch.close
  ch = File.open(Samples[1], 'r'); Cv2 = ch.read; ch.close
  Memory1 = Sisimai::Mail::Memory.new(Cv1)
  Memory2 = Sisimai::Mail::Memory.new(Cv2)

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Mail::Memory, e }
    Methods[:object].each do |e|
      assert_respond_to Memory1, e
      assert_respond_to Memory2, e
    end
  end

  def test_new
    assert_instance_of Sisimai::Mail::Memory, Sisimai::Mail::Memory.new(Cv1)
    assert_instance_of Sisimai::Mail::Memory, Sisimai::Mail::Memory.new(Cv2)

    ce = assert_raises ArgumentError do
      Sisimai::Mail::Memory.new()
      Sisimai::Mail::Memory.new(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_path
    assert_instance_of String, Memory1.path
    assert_instance_of String, Memory2.path
    assert_equal   '<MEMORY>', Memory1.path
    assert_equal   '<MEMORY>', Memory2.path

    ce = assert_raises ArgumentError do
      Memory1.path(nil)
      Memory1.path(nil, nil)
      Memory2.path(nil)
      Memory2.path(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_size
    assert_instance_of Integer, Memory1.size
    assert_instance_of Integer, Memory2.size
    assert_equal true,     Memory1.size > 0
    assert_equal Cv1.size, Memory1.size
    assert_equal true,     Memory1.size > 0
    assert_equal Cv2.size, Memory2.size

    ce = assert_raises ArgumentError do
      Memory1.size(nil)
      Memory1.size(nil, nil)
      Memory2.size(nil)
      Memory2.size(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_offset
    assert_instance_of Integer, Memory1.offset
    assert_instance_of Integer, Memory2.offset
    assert_equal true, Memory1.offset > -1
    assert_equal true, Memory2.offset > -1

    ce = assert_raises ArgumentError do
      Memory1.offset(nil)
      Memory1.offset(nil, nil)
      Memory2.offset(nil)
      Memory2.offset(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_payload
    assert_instance_of Array, Memory1.payload
    assert_instance_of Array, Memory2.payload
    refute_nil Memory1.payload
    refute_nil Memory2.payload

    ce = assert_raises ArgumentError do
      Memory1.payload(nil)
      Memory1.payload(nil, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_read
    ci = 0
    while r = Memory1.read do
      ci += 1
      assert_instance_of String, r
      refute_empty r
      assert_match /\AFrom /, r
      assert_match /[\r\n]/,  r
      assert_equal true, Memory1.offset > 0
    end
    assert_equal Memory1.offset, ci

    ci = 0
    while r = Memory2.read do
      ci += 1
      assert_instance_of String, r
      refute_empty r
      refute_match /\AFrom /, r
      assert_match /[\r\n]/,  r
      assert_equal true, Memory1.offset > 0
    end
    assert_equal Memory2.offset, ci
  end

end

