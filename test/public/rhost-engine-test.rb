require 'minitest/autorun'
require 'sisimai/lhost'
require 'sisimai/rhost'
require './test/public/lhost-code'

module RhostEngineTest
  class PublicChildren < Minitest::Test
    Ro = LhostCode.new("PUBLIC-RHOST-ENGINE-TEST")

    def test_rhostengine
      directory1 = './test/public'
      patternset = directory1 + '/rhost-*.rb'

      checksonly = ARGV[0] || ''
      emailindex = ARGV[1] || 0

      # % grep -h module lib/sisimai/rhost/*.rb | grep -vE '(Sisimai|Rhost)' | awk '{ print $2 }'
      rhostindex = %w[Cox ExchangeOnline FrancePTT GoDaddy GoogleApps IUA KDDI Spectrum TencentQQ]
      enginelist = []
      enginename = ''

      Dir.glob(patternset).each do |f|
        next if f.end_with?('-test.rb')
        enginelist << f.split('-')[1].sub(/[.]rb\z/, '')
      end

      enginelist.each do |e|
        require sprintf("%s/rhost-%s.rb", directory1, e)
        enginename = rhostindex.select { |v| v.downcase == e }.shift
        rhostclass = Module.const_get('RhostEngineTest::Public::' << enginename)
        Ro.enginetest(enginename, rhostclass::IsExpected, false, emailindex)
      end

      printf("\n%d public rhost engines, %d assertions, %d failures\n", enginelist.size, Ro.assertions, Ro.failures.size)
    end
  end
end

