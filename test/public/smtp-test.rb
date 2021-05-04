require 'minitest/autorun'
require 'sisimai/smtp'

class SMTPTest < Minitest::Test
  def test_module
    assert_equal Module, Sisimai::SMTP.class
  end
end
