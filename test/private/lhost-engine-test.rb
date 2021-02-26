require 'minitest/autorun'
require 'sisimai/lhost'
require './test/public/lhost-code'

module LhostEngineTest
  class PrivateChildren < Minitest::Test
    Lx = LhostCode.new("PRIVATE-LHOST-ENGINE-TEST")

    def test_lhostengine
      directory1 = './test/private'
      patternset = ['lhost-*.rb', 'arf-*.rb', 'rfc3464.rb', 'rfc3834.rb'].map { |e| e = directory1 + '/' << e }
      patternset.map { |e| e = directory1 + e }

      checksonly = ARGV[0] || ''
      emailindex = ARGV[1] || 0
      lhostindex = Sisimai::Lhost.index; lhostindex << 'ARF' << 'RFC3464' << 'RFC3834'
      otherlhost = %w[arf rfc3464 rfc3834]
      enginelist = []
      enginename = ''
      checksonly = '' if lhostindex.select { |v| v.downcase == checksonly.downcase }.empty?

      Dir.glob(patternset).each do |f|
        next if f.end_with?('-test.rb')
        next if f.end_with?('-code.rb')

        if checksonly.size > 0
          enginelist << checksonly
          break
        else
          if f.include?('-')
            enginelist << f.split('-')[1].sub(/[.]rb\z/, '')
          else
            enginelist << f.split('/')[-1].sub(/[.]rb\z/, '')
          end
        end
      end

      enginelist.each do |e|
        if otherlhost.include?(e)
          require sprintf("%s/%s.rb", directory1, e)
        else
          require sprintf("%s/lhost-%s.rb", directory1, e)
        end

        enginename = lhostindex.select { |v| v.downcase == e }.shift
        lhostclass = Module.const_get('LhostEngineTest::Private::' << enginename)
        Lx.enginetest(enginename, lhostclass::IsExpected, true, emailindex)
      end

      printf("\n%d private lhost engines, %d assertions, %d failures\n", enginelist.size, Lx.assertions, Lx.failures.size)
    end
  end
end

