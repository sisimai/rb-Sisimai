require 'minitest/autorun'
require 'sisimai/order'

class OrderTest < Minitest::Test
  Methods = { class:  %w[make default another] }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Order, e }
  end

  def test_default
    cv = Sisimai::Order.default
    assert_instance_of Array, cv
    refute_empty cv

    cv.each do |e|
      assert_instance_of String, e
      assert_match /\ASisimai::Lhost::/, e

      cf = './lib/' << e.gsub('::', '/').downcase + '.rb'
      assert_equal true, File.exist?(cf)
      # assert_equal true, require(cf)
      # assert Module.const_get(e)
    end

    ce = assert_raises ArgumentError do
      Sisimai::Order.default(nil)
      Sisimai::Order.default(nil, nil)
    end
  end

  def test_another
    cv = Sisimai::Order.another
    assert_instance_of Array, cv
    refute_empty cv

    cv.each do |e|
      assert_instance_of String, e
      assert_match /\ASisimai::Lhost::/, e

      cf = 'lib/' << e.gsub('::', '/').downcase + '.rb'
      assert_equal true, File.exist?(cf), cf
    end

    ce = assert_raises ArgumentError do
      Sisimai::Order.another(nil)
      Sisimai::Order.another(nil, nil)
    end
  end

  def test_make
    cv = Sisimai::Order.make('delivery failure')
    assert_instance_of Array, Sisimai::Order.make()
    assert_instance_of Array, cv
    refute_empty cv

    cv.each do |e|
      assert_instance_of String, e
      assert_match /\ASisimai::Lhost::/, e

      cf = 'lib/' << e.gsub('::', '/').downcase + '.rb'
      assert_equal true, File.exist?(cf), cf
    end

    ce = assert_raises ArgumentError do
      Sisimai::Order.make(nil, nil)
    end

    ce = assert_raises NoMethodError do
      Sisimai::Order.make(nil)
    end
  end

end
