require 'minitest/autorun'
class PublicSampleEmailTest < Minitest::Test
  Samples = [
    './set-of-emails/mailbox',
    './set-of-emails/maildir/err',
    './set-of-emails/maildir/bsd',
    './set-of-emails/maildir/dos',
    './set-of-emails/to-be-debugged-because/something-is-wrong',
    './set-of-emails/to-be-parsed-for-test'
  ]

  def test_publicsamples
    Samples.each do |de|
      assert_equal true, File.exist?(de)
      assert_equal true, File.readable?(de)
      assert_equal true, File.executable?(de)

      dr = Dir.open(de)
      while ce = dr.read do
        next if ce == '.'
        next if ce == '..'

        emailfn = sprintf("%s/%s", de, ce)
        lnindex = 0

        assert_equal true,  File.exist?(emailfn),    sprintf("%s: FILE", ce)
        assert_equal true,  File.readable?(emailfn), sprintf("%s: READ", ce)
        assert_equal false, File.empty?(emailfn),    sprintf("%s: SIZE", ce)

        fhandle = File.open(emailfn, 'r')
        while r = fhandle.read do
          lnindex += 1
          assert_match /\x0a\z/, r.scrub, sprintf("%s: LINE(%02d)", ce, lnindex)
          break
        end
        fhandle.close
      end

      dr.close
    end
  end
end

