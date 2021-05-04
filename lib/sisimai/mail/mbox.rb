module Sisimai
  class Mail
    # Sisimai::Mail::Mbox is a mailbox file (UNIX mbox) reader.
    class Mbox
      # :dir    [String]  Directory name of the mbox
      # :file   [String]  File name of the mbox
      # :path   [String]  Path to mbox
      # :size   [Integer] File size of the mbox
      # :offset [Integer]  Offset position for seeking
      # :handle [IO::File] File handle
      attr_reader :dir, :file, :path, :size
      attr_accessor :offset, :handle

      # Constructor of Sisimai::Mail::Mbox
      # @param    [String] argv1          Path to mbox
      # @return   [Sisimai::Mail::Mbox]   Object
      #           [Nil]                   is not specified or does not exist
      def initialize(argv1)
        raise Errno::ENOENT   unless File.exist?(argv1)
        raise 'is not a file' unless File.ftype(argv1) == 'file'

        @path   = argv1
        @dir    = File.dirname(argv1)
        @file   = File.basename(argv1)
        @size   = File.size(argv1)
        @offset = 0
        @handle = File.open(argv1, 'r:UTF-8')
      end

      # Mbox reader, works as an iterator.
      # @return   [String] Contents of mbox
      def read
        return nil unless self.offset < self.size

        seekoffset = self.offset || 0
        filehandle = self.handle
        readbuffer = ''
        frombuffer = ''

        begin
          seekoffset = 0 if seekoffset < 0
          filehandle.seek(seekoffset, 0)

          filehandle.each_line do |r|
            # Read the UNIX mbox file from 'From ' to the next 'From '
            if r.start_with?('From ') && !readbuffer.empty?
              frombuffer = r
              break
            end
            readbuffer << r
          end

          seekoffset = filehandle.pos - frombuffer.bytesize
          frombuffer = ''
          self.offset = seekoffset
          filehandle.close unless self.offset < self.size
        end

        return readbuffer.to_s
      end
    end
  end
end

