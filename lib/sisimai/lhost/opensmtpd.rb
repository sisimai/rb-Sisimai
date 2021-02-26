module Sisimai::Lhost
  # Sisimai::Lhost::OpenSMTPD parses a bounce email which created by OpenSMTPD. Methods in the module
  # are called from only Sisimai::Message.
  module OpenSMTPD
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^[ ]+Below is a copy of the original message:|.freeze
      StartingOf = {
        # http://www.openbsd.org/cgi-bin/man.cgi?query=smtpd&sektion=8
        # opensmtpd-5.4.2p1/smtpd/
        #   bounce.c/317:#define NOTICE_INTRO \
        #   bounce.c/318:    "    Hi!\n\n"    \
        #   bounce.c/319:    "    This is the MAILER-DAEMON, please DO NOT REPLY to this e-mail.\n"
        #   bounce.c/320:
        #   bounce.c/321:const char *notice_error =
        #   bounce.c/322:    "    An error has occurred while attempting to deliver a message for\n"
        #   bounce.c/323:    "    the following list of recipients:\n\n";
        #   bounce.c/324:
        #   bounce.c/325:const char *notice_warning =
        #   bounce.c/326:    "    A message is delayed for more than %s for the following\n"
        #   bounce.c/327:    "    list of recipients:\n\n";
        #   bounce.c/328:
        #   bounce.c/329:const char *notice_warning2 =
        #   bounce.c/330:    "    Please note that this is only a temporary failure report.\n"
        #   bounce.c/331:    "    The message is kept in the queue for up to %s.\n"
        #   bounce.c/332:    "    You DO NOT NEED to re-send the message to these recipients.\n\n";
        #   bounce.c/333:
        #   bounce.c/334:const char *notice_success =
        #   bounce.c/335:    "    Your message was successfully delivered to these recipients.\n\n";
        #   bounce.c/336:
        #   bounce.c/337:const char *notice_relay =
        #   bounce.c/338:    "    Your message was relayed to these recipients.\n\n";
        #   bounce.c/339:
        message: ['    This is the MAILER-DAEMON, please DO NOT REPLY to this '],
      }.freeze
      MessagesOf = {
        # smtpd/queue.c:221|  envelope_set_errormsg(&evp, "Envelope expired");
        'expired' => ['Envelope expired'],
        # smtpd/mta.c:976|  relay->failstr = "Invalid domain name";
        # smtpd/mta.c:980|  relay->failstr = "Domain does not exist";
        'hostunknown' => [
          'Invalid domain name',
          'Domain does not exist',
        ],
        # smtp/mta.c:1085|  relay->failstr = "Destination seem to reject all mails";
        'notaccept' => ['Destination seem to reject all mails'],
        #  smtpd/mta.c:972|  relay->failstr = "Temporary failure in MX lookup";
        'networkerror' => [
          'Address family mismatch on destination MXs',
          'All routes to destination blocked',
          'bad DNS lookup error code',
          'Could not retrieve source address',
          'Loop detected',
          'Network error on destination MXs',
          'No MX found for domain',
          'No MX found for destination',
          'No valid route to remote MX',
          'No valid route to destination',
          'Temporary failure in MX lookup',
        ],
        # smtpd/mta.c:1013|  relay->failstr = "Could not retrieve credentials";
        'securityerror' => ['Could not retrieve credentials'],
      }.freeze

      # Parse bounce messages from OpenSMTPD
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('Delivery status notification')
        return nil unless mhead['from'].start_with?('Mailer Daemon <')
        return nil unless mhead['received'].any? { |a| a.include?(' (OpenSMTPD) with ') }

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

          #    Hi!
          #
          #    This is the MAILER-DAEMON, please DO NOT REPLY to this e-mail.
          #
          #    An error has occurred while attempting to deliver a message for
          #    the following list of recipients:
          #
          # kijitora@example.jp: 550 5.2.2 <kijitora@example>... Mailbox Full
          #
          #    Below is a copy of the original message:
          v = dscontents[-1]

          if cv = e.match(/\A([^ ]+?[@][^ ]+?):?[ ](.+)\z/)
            # kijitora@example.jp: 550 5.2.2 <kijitora@example>... Mailbox Full
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            v['diagnosis'] = cv[2]
            recipients += 1
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
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
      def description; return 'OpenSMTPD'; end
    end
  end
end

