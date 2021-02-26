module Sisimai::Lhost
  # Sisimai::Lhost::EinsUndEins parses a bounce email which created by 1&1. Methods in the module are
  # called from only Sisimai::Message.
  module EinsUndEins
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^---[ ]The[ ]header[ ]of[ ]the[ ]original[ ]message[ ]is[ ]following[.][ ]---|.freeze
      StartingOf = {
        message: ['This message was created automatically by mail delivery software'],
        error:   ['For the following reason:'],
      }.freeze
      MessagesOf = { 'mesgtoobig' => ['Mail size limit exceeded'] }.freeze

      # Parse bounce messages from 1&1
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['from'].start_with?('"Mail Delivery System"')
        return nil unless mhead['subject'] == 'Mail delivery failed: returning message to sender'

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # The following address failed:
          #
          # general@example.eu
          #
          # For the following reason:
          #
          # Mail size limit exceeded. For explanation visit
          # http://postmaster.1and1.com/en/error-messages?ip=%1s
          v = dscontents[-1]

          if cv = e.match(/\A([^ ]+[@][^ ]+?)[:]?\z/)
            # general@example.eu
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            recipients += 1

          elsif e.start_with?(StartingOf[:error][0])
            # For the following reason:
            v['diagnosis'] = e
          else
            if v['diagnosis']
              # Get error message and append error message strings
              v['diagnosis'] << ' ' << e
            else
              # OR the following format:
              #   neko@example.fr:
              #   SMTP error from remote server for TEXT command, host: ...
              v['alterrors'] ||= ''
              v['alterrors'] << ' ' << e
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] ||= ''
          e['diagnosis']   = e['alterrors'] if e['diagnosis'].empty?

          if cv = e['diagnosis'].match(/host:[ ]+(.+?)[ ]+.+[ ]+reason:.+/)
            # SMTP error from remote server for TEXT command,
            #   host: smtp-in.orange.fr (193.252.22.65)
            #   reason: 550 5.2.0 Mail rejete. Mail rejected. ofr_506 [506]
            e['rhost']   = cv[1]
            e['command'] = 'DATA' if e['diagnosis'] =~ /for TEXT command/
            e['spec']    = 'SMTP' if e['diagnosis'] =~ /SMTP error/
            e['status']  = Sisimai::SMTP::Status.find(e['diagnosis'])
          else
            # For the following reason:
            e['diagnosis'].gsub(/\A#{StartingOf[:error][0]}/, '')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return '1&1: https://www.1und1.de'; end
    end
  end
end

