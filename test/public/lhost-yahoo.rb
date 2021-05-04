module LhostEngineTest::Public
  module Yahoo
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '03' => [['5.1.1',   '550', 'userunknown',     true]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '05' => [['5.2.1',   '550', 'userunknown',     true]],
      '06' => [['5.0.910', '550', 'filtered',        false]],
      '07' => [['5.0.911', '550', 'userunknown',     true]],
      '08' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '09' => [['5.0.932', '',    'notaccept',       true]],
      '10' => [['5.1.1',   '550', 'userunknown',     true]],
      '11' => [['5.1.8',   '501', 'rejected',        false]],
      '12' => [['5.1.8',   '501', 'rejected',        false]],
      '13' => [['5.0.947', '',    'expired',         false]],
      '14' => [['5.0.971', '554', 'blocked',         false]],
    }
  end
end

