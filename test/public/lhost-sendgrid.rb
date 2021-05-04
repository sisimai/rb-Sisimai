module LhostEngineTest::Public
  module SendGrid
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.0.947', '',    'expired',         false]],
    }
  end
end

