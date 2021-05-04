module Sisimai
  class Mail
    # Sisimai::Mail::Memory is a class for reading an email string
    class Memory
      # :path    [String]  Fixed string "<MEMORY>"
      # :size    [Integer] data size of the email text
      # :payload [Array]   Entire bounce mail message
      # :offset  [Integer] Index of ":payload"
      attr_reader :path, :size
      attr_accessor :payload, :offset

      # Constructor of Sisimai::Mail::Memory
      # @param    [String] argv1          Entire email string
      # @return   [Sisimai::Mail::Memory] Object
      #           [Nil]                   is not specified or does not exist
      def initialize(argv1)
        raise 'is not a String' unless argv1.is_a? ::String
        raise 'is empty'        if argv1.empty?

        @path    = '<MEMORY>'
        @size    = argv1.size
        @payload = []
        @offset  = 0

        if argv1.start_with?('From ')
          # UNIX mbox
          @payload = argv1.split(/^From /).map! { |e| e = 'From ' + e }
          @payload.shift
        else
          @payload = [argv1]
        end
      end

      # Memory reader, works as an iterator.
      # @return   [String] Contents of a bounce mail
      def read
        return nil if self.payload.empty?
        self.offset += 1
        return self.payload.shift
      end
    end
  end
end

