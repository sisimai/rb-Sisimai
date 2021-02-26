module LhostEngineTest::Public
  module X2
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.910', '',    'filtered',        false]],
      '02' => [['5.0.910', '',    'filtered',        false],
               ['5.0.921', '',    'suspend',         false],
               ['5.0.910', '',    'filtered',        false]],
      '03' => [['5.0.947', '',    'expired',         false]],
      '04' => [['5.0.922', '',    'mailboxfull',     false]],
      '05' => [['4.1.9',   '',    'expired',         false]],
    }
  end
end

