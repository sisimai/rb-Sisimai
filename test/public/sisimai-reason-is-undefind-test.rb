require 'minitest/autorun'
require 'sisimai'

class ReasonIsUndefinedTest < Minitest::Test
  Samples = './set-of-emails/to-be-debugged-because/reason-is-undefined'

  if Dir.exist?(Samples)
    cv = Sisimai.rise(Samples)
    assert_instance_of Array, cv
    refute_empty cv
  end
end
