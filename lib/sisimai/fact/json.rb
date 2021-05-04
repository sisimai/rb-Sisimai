module Sisimai
  class Fact
    # Sisimai::Fact::JSON dumps parsed data object as a JSON format. This class and method should be
    # called from the parent object "Sisimai::Fact".
    module JSON
      class << self
        # Serializer (JSON)
        # @param    [Sisimai::Fact] argvs Object
        # @return   [String, nil]         Dumped data or nil if the argument is missing
        def dump(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Fact

          if RUBY_PLATFORM.start_with?('java')
            # java-based ruby environment like JRuby.
            begin
              require 'jrjackson'
              jsonstring = JrJackson::Json.dump(argvs.damn)
            rescue StandardError => ce
              warn '***warning: Failed to JrJackson::Json.dump: ' << ce.to_s
            end
          else
            # MRI
            begin
              require 'oj'
              jsonstring = Oj.dump(argvs.damn, :mode => :compat)
            rescue StandardError => ce
              warn '***warning: Failed to Oj.dump: ' << ce.to_s
            end
          end

          return jsonstring
        end

      end
    end
  end
end
