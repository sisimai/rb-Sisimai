module Sisimai::Lhost
  # Sisimai::Lhost::Amavis parses a bounce email which created by amavsid-new. Methods in the module
  # are called from only Sisimai::Message.
  module Amavis
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]text/rfc822-headers|.freeze
      StartingOf = { message: ['The message '] }.freeze
      MessagesOf = {
        # amavisd-new-2.11.1/amavisd:1840|%smtp_reason_by_ccat = (
        # amavisd-new-2.11.1/amavisd:1840|  # currently only used for blocked messages only, status 5xx
        # amavisd-new-2.11.1/amavisd:1840|  # a multiline message will produce a valid multiline SMTP response
        # amavisd-new-2.11.1/amavisd:1840|  CC_VIRUS,       'id=%n - INFECTED: %V',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BANNED,      'id=%n - BANNED: %F',
        # amavisd-new-2.11.1/amavisd:1840|  CC_UNCHECKED.',1', 'id=%n - UNCHECKED: encrypted',
        # amavisd-new-2.11.1/amavisd:1840|  CC_UNCHECKED.',2', 'id=%n - UNCHECKED: over limits',
        # amavisd-new-2.11.1/amavisd:1840|  CC_UNCHECKED,      'id=%n - UNCHECKED',
        # amavisd-new-2.11.1/amavisd:1840|  CC_SPAM,        'id=%n - spam',
        # amavisd-new-2.11.1/amavisd:1840|  CC_SPAMMY.',1', 'id=%n - spammy (tag3)',
        # amavisd-new-2.11.1/amavisd:1840|  CC_SPAMMY,      'id=%n - spammy',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',1',   'id=%n - BAD HEADER: MIME error',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',2',   'id=%n - BAD HEADER: nonencoded 8-bit character',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',3',   'id=%n - BAD HEADER: contains invalid control character',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',4',   'id=%n - BAD HEADER: line made up entirely of whitespace',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',5',   'id=%n - BAD HEADER: line longer than RFC 5322 limit',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',6',   'id=%n - BAD HEADER: syntax error',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',7',   'id=%n - BAD HEADER: missing required header field',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH.',8',   'id=%n - BAD HEADER: duplicate header field',
        # amavisd-new-2.11.1/amavisd:1840|  CC_BADH,        'id=%n - BAD HEADER',
        # amavisd-new-2.11.1/amavisd:1840|  CC_OVERSIZED,   'id=%n - Message size exceeds recipient\'s size limit',
        # amavisd-new-2.11.1/amavisd:1840|  CC_MTA.',1',    'id=%n - Temporary MTA failure on relaying',
        # amavisd-new-2.11.1/amavisd:1840|  CC_MTA.',2',    'id=%n - Rejected by next-hop MTA on relaying',
        # amavisd-new-2.11.1/amavisd:1840|  CC_MTA,         'id=%n - Unable to relay message back to MTA',
        # amavisd-new-2.11.1/amavisd:1840|  CC_CLEAN,       'id=%n - CLEAN',
        # amavisd-new-2.11.1/amavisd:1840|  CC_CATCHALL,    'id=%n - OTHER',  # should not happen
        # ...
        # amavisd-new-2.11.1/amavisd:15289|my $status = setting_by_given_contents_category(
        # amavisd-new-2.11.1/amavisd:15289|  $blocking_ccat,
        # amavisd-new-2.11.1/amavisd:15289|  { CC_VIRUS,       "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_BANNED,      "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_UNCHECKED,   "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_SPAM,        "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_SPAMMY,      "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_BADH.",2",   "554 5.6.3",  # nonencoded 8-bit character
        # amavisd-new-2.11.1/amavisd:15289|    CC_BADH,        "554 5.6.0",
        # amavisd-new-2.11.1/amavisd:15289|    CC_OVERSIZED,   "552 5.3.4",
        # amavisd-new-2.11.1/amavisd:15289|    CC_MTA,         "550 5.3.5",
        # amavisd-new-2.11.1/amavisd:15289|    CC_CATCHALL,    "554 5.7.0",
        # amavisd-new-2.11.1/amavisd:15289|  });
        # ...
        # amavisd-new-2.11.1/amavisd:15332|my $response = sprintf("%s %s%s%s", $status,
        # amavisd-new-2.11.1/amavisd:15333|  ($final_destiny == D_PASS     ? "Ok" :
        # amavisd-new-2.11.1/amavisd:15334|   $final_destiny == D_DISCARD  ? "Ok, discarded" :
        # amavisd-new-2.11.1/amavisd:15335|   $final_destiny == D_REJECT   ? "Reject" :
        # amavisd-new-2.11.1/amavisd:15336|   $final_destiny == D_BOUNCE   ? "Bounce" :
        # amavisd-new-2.11.1/amavisd:15337|   $final_destiny == D_TEMPFAIL ? "Temporary failure" :
        # amavisd-new-2.11.1/amavisd:15338|                                  "Not ok ($final_destiny)" ),
        'spamdetected'  => [' - spam'],
        'virusdetected' => [' - infected'],
        'contenterror'  => [' - bad header:'],
        'exceedlimit'   => [' - message size exceeds recipient'],
        'systemerror'   => [
            ' - temporary mta failure on relaying',
            ' - rejected by next-hop mta on relaying',
            ' - unable to relay message back to mta',
        ],
      }.freeze

      # Parse bounce messages from amavisd-new
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      # @since v4.25.0
      def inquire(mhead, mbody)
        # From: "Content-filter at neko1.example.jp" <postmaster@neko1.example.jp>
        # Subject: Undeliverable mail, MTA-BLOCKED
        return nil unless mhead['from'].to_s.start_with?('"Content-filter at ')

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

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
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?
          next unless f = Sisimai::RFC1894.match(e)

          # "e" matched with any field defined in RFC3464
          next unless o = Sisimai::RFC1894.field(e)
          v = dscontents[-1]

          if o[-1] == 'addr'
            # Final-Recipient: rfc822; kijitora@example.jp
            # X-Actual-Recipient: rfc822; kijitora@example.co.jp
            if o[0] == 'final-recipient'
              # Final-Recipient: rfc822; kijitora@example.jp
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = o[2]
              recipients += 1
            else
              # X-Actual-Recipient: rfc822; kijitora@example.co.jp
              v['alias'] = o[2]
            end
          elsif o[-1] == 'code'
            # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
            v['spec'] = o[1]
            v['diagnosis'] = o[2]
          else
            # Other DSN fields defined in RFC3464
            next unless fieldtable[o[0]]
            v[fieldtable[o[0]]] = o[2]

            next unless f == 1
            permessage[fieldtable[o[0]]] = o[2]
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].to_s.tr("\n", ' '))
          q = e['diagnosis'].downcase
          catch :DETECT_REASON do
            MessagesOf.each_key do |p|
              # Try to detect an error reason
              MessagesOf[p].each do |r|
                # Try to find an error message including lower-cased string defined in MessagesOf constant
                next unless q.include?(r)
                e['reason'] = p
                throw :DETECT_REASON
              end
            end
          end
        end
        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'amavisd-new: https://www.amavis.org/'; end
    end
  end
end

