module LhostEngineTest::Public
  module GMX
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.2.2',   '',    'mailboxfull',     false]],
      '02' => [['5.1.1',   '',    'userunknown',     true]],
      '03' => [['5.2.1',   '',    'userunknown',     true],
               ['5.2.2',   '',    'mailboxfull',     false]],
      '04' => [['5.0.947', '',    'expired',         false]],
    }
  end
end

