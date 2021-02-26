module Sisimai
  class Mail
    # Sisimai::Mail::Maildir is a reader for getting contents of each email in the Maildir/ directory.
    class Maildir
      # :dir    [String] Path to Maildir/
      # :size   [Integer] The number of files/directories in the Maildir/
      # :path   [String] Path to each file
      # :file,  [String] Each file name of a mail in the Maildir/
      # :offset [Integer] The number of email files in the Maildir/
      # :handle [IO::Dir] Directory handle
      attr_reader :dir
      attr_accessor :size, :path, :file, :offset, :handle

      # Constructor of Sisimai::Mail::Maildir
      # @param    [String] argvs            Path to Maildir/
      # @return   [Sisimai::Mail::Maildir]  Object
      #           [Nil]                     is not a directory or does not exist
      def initialize(argv1)
        raise Errno::ENOENT  unless File.exist?(argv1)
        raise Errno::ENOTDIR unless File.ftype(argv1) == 'directory'

        @path   = nil
        @size   = Dir.entries(argv1).size
        @dir    = argv1
        @file   = nil
        @offset = 0
        @handle = Dir.open(argv1)
      end

      # Maildir reader, works as a iterator.
      # @return       [String] Contents of file in Maildir/
      def read
        return nil unless self.offset < self.size
        seekhandle = self.handle
        readbuffer = ''

        begin
          while r = seekhandle.read do
            # Read each file in the directory
            if r == '.' || r == '..'
              # Is a directory
              self.offset += 1
              next
            end

            emailindir = (self.dir + '/' + r).squeeze('/')
            if File.ftype(emailindir) != 'file' ||
               File.size(emailindir) == 0 ||
               File.readable?(emailindir) == false
              # The file is not a file, is empty, is not readable
              self.offset += 1
              next
            end

            File.open(emailindir, 'r:UTF-8') do |f|
              readbuffer = f.read
            end

            self.offset += 1
            self.path    = emailindir
            self.file    = r
            break
          end
          seekhandle.close unless self.offset < self.size
        end

        return readbuffer
      end

    end
  end
end

