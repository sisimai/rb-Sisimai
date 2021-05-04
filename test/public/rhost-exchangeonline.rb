module RhostEngineTest::Public
  module ExchangeOnline
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.7.606', '550', 'blocked',         false]],
      '02' => [['5.4.1',   '550', 'rejected',        false]],
      '03' => [['5.1.10',  '550', 'userunknown',     true]],
    }
  end
end

