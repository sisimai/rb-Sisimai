module LhostEngineTest::Public
  module MessagingServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.0',   '522', 'mailboxfull',     false]],
      '03' => [['5.7.1',   '550', 'filtered',        false],
               ['5.7.1',   '550', 'filtered',        false]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '05' => [['5.4.4',   '',    'hostunknown',     true]],
      '06' => [['5.2.1',   '550', 'filtered',        false]],
      '07' => [['4.4.7',   '',    'expired',         false]],
      '08' => [['5.0.0',   '550', 'filtered',        false]],
      '09' => [['5.0.0',   '550', 'userunknown',     true]],
      '10' => [['5.0.932', '',    'notaccept',       true]],
      '11' => [['5.1.8',   '501', 'rejected',        false]],
      '12' => [['4.2.2',   '',    'mailboxfull',     false]],
    }
  end
end

