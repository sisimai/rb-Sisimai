module LhostEngineTest::Public
  module OpenSMTPD
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false],
               ['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.0.912', '',    'hostunknown',     true]],
      '04' => [['5.0.944', '',    'networkerror',    false]],
      '05' => [['5.0.947', '',    'expired',         false]],
      '06' => [['5.0.947', '',    'expired',         false]],
    }
  end
end

