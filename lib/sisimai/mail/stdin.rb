module Sisimai
  class Mail
    # Sisimai::Mail::STDIN is a reader for getting contents of each email from STDIN
    class STDIN
      # :path   [String]  Fixed string "<STDIN>"
      # :size   [Integer] Data size which has been read
      # :offset [Integer]  The number of emails which have neen read
      # :handle [IO::File] File handle
      attr_reader :path, :name, :size
      attr_accessor :offset, :handle

      # Constructor of Sisimai::Mail::STDIN
      # @param    [IO::STDIN] stdin      Standard-In
      # @return   [Sisimai::Mail::STDIN] Object
      def initialize(stdin = $stdin)
        raise 'is not an IO object' unless stdin.is_a?(IO)

        @path   = '<STDIN>'
        @size   = nil
        @offset = 0
        @handle = stdin
      end

      # Mbox reader, works as a iterator.
      # @return   [String] Contents of mbox
      def read
        readhandle = self.handle
        readbuffer = ''

        if readhandle
          return nil if readhandle.closed?
        end

        begin
          readhandle = STDIN unless readhandle
          while r = readhandle.gets
            break if readbuffer.size > 0 && r.start_with?('From ')
            readbuffer << r
          end
        ensure
          readhandle.close
        end

        self.size   += readbuffer.size
        self.offset += 1
        return readbuffer
      end
    end
  end
end

