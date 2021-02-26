module LhostEngineTest::Public
  module X3
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.3.0',   '553', 'userunknown',     true]],
      '02' => [['5.0.947', '',    'expired',         false]],
      '03' => [['5.3.0',   '553', 'userunknown',     true]],
      '05' => [['5.0.900', '',    'undefined',       false]],
      '06' => [['5.2.2',   '552', 'mailboxfull',     false]],
    }
  end
end

