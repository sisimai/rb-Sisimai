module Sisimai::Lhost
  # Sisimai::Lhost::GoogleGroups parses a bounce email which created by Google Groups. Methods in the
  # module are called from only Sisimai::Message.
  module GoogleGroups
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r/^-----[ ]Original[ ]message[ ]-----$/.freeze

      # Parse bounce messages from Google Groups
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      # @since v4.25.6
      def inquire(mhead, mbody)
        return nil unless mhead['from'].end_with?('<mailer-daemon@googlemail.com>')
        return nil unless mhead['subject'].start_with?('Delivery Status Notification')
        return nil unless mhead['x-failed-recipients']
        return nil unless mhead['x-failed-recipients'].include?('@googlegroups.com')

        # Hello kijitora@libsisimai.org,
        #
        # We're writing to let you know that the group you tried to contact (group-name)
        # may not exist, or you may not have permission to post messages to the group.
        # A few more details on why you weren't able to post:
        #
        #  * You might have spelled or formatted the group name incorrectly.
        #  * The owner of the group may have removed this group.
        #  * You may need to join the group before receiving permission to post.
        #  * This group may not be open to posting.
        #
        # If you have questions related to this or any other Google Group,
        # visit the Help Center at https://groups.google.com/support/.
        #
        # Thanks,
        #
        # Google Groups
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        recordwide = { 'rhost' => '', 'reason' => '', 'diagnosis' => '' }
        recipients = 0
        v = dscontents[-1]

        # * You might have spelled or formatted the group name incorrectly.
        # * The owner of the group may have removed this group.
        # * You may need to join the group before receiving permission to post.
        # * This group may not be open to posting.
        entiremesg = emailsteak[0].split(/\n\n/, 5).slice(0, 4).join(' ').tr("\n", ' ');
        recordwide['diagnosis'] = Sisimai::String.sweep(entiremesg)
        recordwide['reason']    = emailsteak[0].scan(/^[ ]?[*][ ]?/).size == 4 ? 'rejected' : 'onhold'
        recordwide['rhost']     = Sisimai::RFC5322.received(mhead['received'][0]).shift

        mhead['x-failed-recipients'].split(',').each do |e|
          # X-Failed-Recipients: neko@example.jp, nyaan@example.org, ...
          next unless e.end_with?('@googlegroups.com')
          next unless Sisimai::Address.is_emailaddress(e)

          if v['recipient']
            # There are multiple recipient addresses in the message body.
            dscontents << Sisimai::Lhost.DELIVERYSTATUS
            v = dscontents[-1]
          end
          v['recipient'] = Sisimai::Address.s3s4(e)
          recipients += 1
          recordwide.each_key { |r| v[r] = recordwide[r] }
        end
        return nil unless recipients > 0
        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end
      def description; return 'Google Groups: https://groups.google.com'; end
    end
  end
end

