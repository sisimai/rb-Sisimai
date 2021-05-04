module Sisimai
  # Sisimai::RFC5322 provide methods for checking email address.
  module RFC5322
    class << self
      HeaderTable = {
        :messageid => %w[message-id],
        :subject   => %w[subject],
        :listid    => %w[list-id],
        :date      => %w[date posted-date posted resent-date],
        :addresser => %w[from return-path reply-to errors-to reverse-path x-postfix-sender envelope-from x-envelope-from],
        :recipient => %w[to delivered-to forward-path envelope-to x-envelope-to resent-to apparently-to],
      }.freeze

      build_flatten_rfc822header_list = lambda do
        # Convert HEADER: structured hash table to flatten hash table for being called from Sisimai::Lhost::*
        fv = {}
        HeaderTable.each_value do |e|
          e.each { |ee| fv[ee] = true }
        end
        return fv
      end
      HeaderIndex = build_flatten_rfc822header_list.call

      # Grouped RFC822 headers
      # @param    [Symbol] group  RFC822 Header group name
      # @return   [Array,Hash]    RFC822 Header list
      def HEADERFIELDS(group = '')
        return HeaderIndex if group.empty?
        return HeaderTable[group] if HeaderTable[group]
        return HeaderTable
      end

      # Fields that might be long
      # @return   [Hash] Long filed(email header) list
      def LONGFIELDS
        return { 'to' => true, 'from' => true, 'subject' => true, 'message-id' => true }
      end

      # Convert Received headers to a structured data
      # @param    [String] argvs  Received header
      # @return   [Array]         Received header as a structured data
      def received(argvs)
        return [] unless argvs.is_a?(::String)

        hosts = []
        value = { 'from' => '', 'by' => '' }

        # Received: (qmail 10000 invoked by uid 999); 24 Apr 2013 00:00:00 +0900
        return [] if argvs =~ /qmail[ ]+.+invoked[ ]+/

        if cr = argvs.match(/\Afrom[ ]+(.+)[ ]+by[ ]+([^ ]+)/)
          # Received: from localhost (localhost) by nijo.example.jp (V8/cf) id s1QB5ma0018057;
          #   Wed, 26 Feb 2014 06:05:48 -0500
          value['from'] = cr[1]
          value['by']   = cr[2]

        elsif cr = argvs.match(/\bby[ ]+([^ ]+)(.+)/)
          # Received: by 10.70.22.98 with SMTP id c2mr1838265pdf.3; Fri, 18 Jul 2014 00:31:02 -0700 (PDT)
          value['from'] = cr[1] + cr[2]
          value['by']   = cr[1]
        end

        if value['from'].include?(' ')
          # Received: from [10.22.22.222] (smtp.kyoto.ocn.ne.jp [192.0.2.222]) (authenticated bits=0)
          #   by nijo.example.jp (V8/cf) with ESMTP id s1QB5ka0018055; Wed, 26 Feb 2014 06:05:47 -0500
          received = value['from'].split(' ')
          namelist = []
          addrlist = []
          hostname = ''
          hostaddr = ''

          while e = received.shift do
            # Received: from [10.22.22.222] (smtp-gateway.kyoto.ocn.ne.jp [192.0.2.222])
            if e =~ /\A[\[(]\d+[.]\d+[.]\d+[.]\d+[)\]]\z/
              # [192.0.2.1] or (192.0.2.1)
              e = e.delete('[]()')
              addrlist << e
            else
              # hostname
              e = e.delete('()')
              namelist << e
            end
          end

          while e = namelist.shift do
            # 1. Hostname takes priority over all other IP addresses
            next unless e.include?('.')
            hostname = e
            break
          end

          if hostname.empty?
            # 2. Use IP address as a remote host name
            addrlist.each do |e|
              # Skip if the address is a private address
              next if e.start_with?('10.', '127.', '192.168.')
              next if e =~ /\A172[.](?:1[6-9]|2[0-9]|3[0-1])[.]/
              hostaddr = e
              break
            end
          end

          value['from'] = hostname || hostaddr || addrlist[-1]
        end

        %w[from by].each do |e|
          # Copy entries into hosts
          next if value[e].empty?
          value[e] = value[e].delete('[]();?')
          hosts << value[e]
        end
        return hosts
      end

      # Split given entire message body into error message lines and the original message part only
      # include email headers
      # @param    [String] mbody  Entire message body
      # @param    [Regexp] regex  Regular expression of the message/rfc822 or the beginning of the
      #                           original message part
      # @return   [Array]         [Error message lines, The original message]
      # @since    v4.25.5
      def fillet(mbody = '', regex)
        return nil if mbody.empty?
        return nil unless regex

        v = mbody.split(regex, 2)
        v[1] ||= ''

        unless v[1].empty?
          # Remove blank lines, the message body of the original message, and append "\n" at the end
          # of the original message headers
          # 1. Remove leading blank lines
          # 2. Remove text after the first blank line: \n\n
          # 3. Append "\n" at the end of test block when the last character is not "\n"
          v[1].sub!(/\A[\r\n\s]+/, '')
          v[1] = v[1][0, v[1].index("\n\n")] if v[1].include?("\n\n")
          v[1] << "\n" unless v[1].end_with?("\n")
        end
        return v
      end

    end
  end
end

