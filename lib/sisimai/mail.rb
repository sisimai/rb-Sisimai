module Sisimai
  # Sisimai::Mail is a handler of UNIX mbox or Maildir for reading each mail. It is a wrapper class
  # of Sisimai::Mail::Mbox, Sisimai::Mail::Maildir, and Sisimai::Mail::Memory classes.
  class Mail
    # :path [String] path to mbox or Maildir/
    # :kind [String] Data type: mailbox, maildir, or stdin
    # :data [Sisimai::Mail::[Mbox,Maildir,Memory,STDIN]] Object
    attr_reader   :path, :kind
    attr_accessor :data

    # Constructor of Sisimai::Mail
    # @param    [String] argv1        Path to mbox or Maildir/
    # @return   [Sisimai::Mail, Nil]  Object or nil if the argument was wrong
    def initialize(argv1)
      classname = nil
      parameter = { 'path' => argv1, 'kind' => nil, 'data' => nil }

      if argv1.is_a?(::String)
        # Path to mail or '<STDIN>' ?
        if argv1 == '<STDIN>'
          # Sisimai::Mail.new('<STDIN>')
          classname = self.class.to_s << '::STDIN'
          parameter['kind'] = 'stdin'
          parameter['path'] = '<STDIN>'
        else
          # The argumenet is a mailbox or a Maildir/.
          mediatype = argv1.include?("\n") ? 'memory' : File.ftype(argv1)

          if mediatype == 'file'
            # The argument is a file, it is an mbox or email file in Maildir/
            classname = self.class.to_s << '::Mbox'
            parameter['kind'] = 'mailbox'

          elsif mediatype == 'directory'
            # The agument is not a file, it is a Maildir/
            classname = self.class.to_s << '::Maildir'
            parameter['kind'] = 'maildir'

          elsif mediatype == 'memory'
            # The argument is an email string
            classname = self.class.to_s << '::Memory'
            parameter['kind'] = 'memory'
            parameter['path'] = 'MEMORY'
          end
        end
      elsif argv1.is_a?(IO)
        # Read from STDIN, The argument neither a mailbox nor a Maildir/.
        classname = self.class.to_s << '::STDIN'
        parameter['kind'] = 'stdin'
        parameter['path'] = '<STDIN>'
      end
      return nil unless classname

      classpath = classname.gsub('::', '/').downcase
      require classpath
      parameter['data'] = Module.const_get(classname).new(argv1)

      @path = parameter['path']
      @kind = parameter['kind']
      @data = parameter['data']
    end

    # Alias method of Sisimai::Mail.data.read()
    # @return   [String] Contents of mbox/Maildir
    def read
      return nil unless data
      return data.read
    end

  end
end

