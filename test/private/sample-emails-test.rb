require 'minitest/autorun'
class PrivateSampleEmailTest < Minitest::Test
  Samples = [
    './set-of-emails/private',
  ]

  def test_privatesamples
    Samples.each do |de|
      assert_equal true, File.exist?(de)
      assert_equal true, File.readable?(de)
      assert_equal true, File.executable?(de)

      dr = Dir.open(de)
      while ce = dr.read do
        next if ce == '.'
        next if ce == '..'

        assert_equal true, File.exist?(sprintf("%s/%s", de, ce))
        assert_equal true, File.readable?(sprintf("%s/%s", de, ce))
        assert_equal true, File.executable?(sprintf("%s/%s", de, ce))

        sf = Dir.open(sprintf("%s/%s", de, ce))
        while cx = sf.read do
          next if cx == '.'
          next if cx == '..'

          emailfn = sprintf("%s/%s/%s", de, ce, cx)
          lnindex = 0

          assert_equal true,  File.exist?(emailfn),    sprintf("%s: READ", ce)
          assert_equal true,  File.readable?(emailfn), sprintf("%s: READ", ce)
          assert_equal false, File.empty?(emailfn),    sprintf("%s: SIZE", ce)

          fhandle = File.open(emailfn, 'r')
          while r = fhandle.read do
            lnindex += 1
            assert_match /[\r\n]/, r.scrub, sprintf("%s: LINE(%02d)", ce, lnindex)
            break
          end
          fhandle.close
        end
        sf.close
      end

      dr.close
    end
  end
end

