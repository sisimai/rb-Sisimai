module Sisimai
  class Fact
    # Sisimai::Fact::YAML dumps parsed data object as a YAML format. This class and method should be
    # called from the parent object "Sisimai::Fact".
    module YAML
      class << self
        require 'yaml'

        # Serializer (YAML)
        # @param    [Sisimai::Fact] argvs Object
        # @return   [String, nil]         Dumped data or nil if the argument is missing
        def dump(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Fact

          damneddata = argvs.damn
          yamlstring = nil

          begin
            yamlstring = ::YAML.dump(damneddata)
          rescue StandardError => ce
            warn '***warning: Failed to YAML.dump: ' << ce.to_s
          end

          return yamlstring
        end

      end
    end
  end
end
