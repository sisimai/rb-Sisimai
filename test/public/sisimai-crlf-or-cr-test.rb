require 'minitest/autorun'
require 'sisimai'

class EmailCRLFTest < Minitest::Test
  Samples = {
    'dos' => './set-of-emails/maildir/dos',
    'mac' => './set-of-emails/maildir/mac',
  }

  def test_email1
    Samples.each_key do |e|
      next if e == 'mac'

      cv = Sisimai.rise(Samples[e])
      assert_instance_of Array, cv
      refute_empty cv

      cv.each do |ee|
        assert_instance_of Sisimai::Fact, ee
        assert_instance_of Sisimai::Time, ee.timestamp
        assert_instance_of Sisimai::Address, ee.addresser
        assert_instance_of Sisimai::Address, ee.recipient

        assert_match /[@]/, ee.addresser.address
        assert_match /[@]/, ee.recipient.address

        assert_match /\A[a-z].{5,12}\z/, ee.reason
        refute_nil ee.replycode

        dx = ee.damn
        assert_instance_of Hash, dx
        refute_empty dx
        assert_equal ee.addresser.address, dx['addresser']
        assert_equal ee.recipient.address, dx['recipient']

        dx.each_key do |eee|
          next unless dx[eee].is_a? ::String
          next if ee.send(eee).class.to_s.start_with?('Sisimai::')
          next if eee == 'subject'

          if eee == 'catch'
            assert_empty dx['catch']
          else
            assert_equal ee.send(eee.to_sym), dx[eee]
          end
        end

        jx = ee.dump('json')
        assert_instance_of String, jx
        refute_empty jx
      end

    end
  end
end

