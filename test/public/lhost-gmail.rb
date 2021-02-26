module LhostEngineTest::Public
  module Gmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.7.0',   '554', 'filtered',        false]],
      '04' => [['5.7.1',   '554', 'blocked',         false]],
      '05' => [['5.7.1',   '550', 'securityerror',   false]],
      '06' => [['4.2.2',   '450', 'mailboxfull',     false]],
      '07' => [['5.0.930', '500', 'systemerror',     false]],
      '08' => [['5.0.947', '',    'expired',         false]],
      '09' => [['4.0.947', '',    'expired',         false]],
      '10' => [['5.0.947', '',    'expired',         false]],
      '11' => [['5.0.947', '',    'expired',         false]],
      '15' => [['5.0.947', '',    'expired',         false]],
      '16' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '17' => [['4.0.947', '',    'expired',         false]],
      '18' => [['5.1.1',   '550', 'userunknown',     true]],
      '19' => [['5.0.922', '',    'mailboxfull',     false]],
    }
  end
end

