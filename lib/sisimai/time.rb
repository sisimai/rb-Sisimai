require 'date'
module Sisimai
  # Sisimai::Time is a child class of Date for Sisimai::Fact
  class Time < ::DateTime
    def to_json(*)
      return self.to_time.to_i
    end
  end
end
