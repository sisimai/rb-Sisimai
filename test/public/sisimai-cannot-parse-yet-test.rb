require 'minitest/autorun'
require 'sisimai'

class EmailCouldNotBeParsedTest < Minitest::Test
  Samples = './set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet'

  if Dir.exist?(Samples)
    cv = Sisimai.rise(Samples)
    assert_instance_of Array, cv
    assert_empty cv
  end
end

