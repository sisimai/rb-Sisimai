require 'minitest/autorun'
require 'sisimai/lhost'

class LhostTest < Minitest::Test
  Methods = { class:  %w[description inquire index path DELIVERYSTATUS INDICATORS] }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Lhost, e }
  end

  def test_description
    assert_empty Sisimai::Lhost.description

    ce = assert_raises ArgumentError do
      Sisimai::Lhost.description(nil)
      Sisimai::Order.description(nil, nil)
    end
  end

  def test_inquire
    assert_nil Sisimai::Lhost.inquire

    ce = assert_raises ArgumentError do
      Sisimai::Lhost.inquire(nil)
      Sisimai::Lhost.inquire(nil, nil)
    end
  end

  def test_index
    cv = Sisimai::Lhost.index
    assert_instance_of Array, cv
    assert_equal true, cv.size > 0

    ce = assert_raises ArgumentError do
      Sisimai::Lhost.index(nil)
      Sisimai::Lhost.index(nil, nil)
    end
  end

  def test_path
    cv = Sisimai::Lhost.path
    assert_instance_of Hash, cv
    assert_equal true, cv.keys.size > 0

    ce = assert_raises ArgumentError do
      Sisimai::Lhost.path(nil)
      Sisimai::Lhost.path(nil, nil)
    end
  end

  def test_DELIVERYSTATUS
    cv = Sisimai::Lhost.DELIVERYSTATUS
    assert_instance_of Hash, cv
    assert_equal 15, cv.keys.size

    ce = assert_raises ArgumentError do
      Sisimai::Lhost.DELIVERYSTATUS(nil)
      Sisimai::Lhost.DELIVERYSTATUS(nil, nil)
    end
  end

  def test_INDICATORS
    cv = Sisimai::Lhost.INDICATORS
    assert_instance_of Hash, cv
    assert_equal 2, cv.keys.size

    ce = assert_raises ArgumentError do
      Sisimai::Lhost.INDICATORS(nil)
      Sisimai::Lhost.INDICATORS(nil, nil)
    end
  end

end

