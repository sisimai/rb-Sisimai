module LhostEngineTest::Private
  module OpenSMTPD
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.2.1',   '550', 'filtered',        false]],
      '01003' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01004' => [['5.0.910', '550', 'filtered',        false]],
      '01005' => [['5.0.910', '550', 'filtered',        false]],
      '01006' => [['5.0.947', '',    'expired',         false]],
      '01007' => [['5.1.1',   '550', 'userunknown',     true]],
      '01008' => [['5.2.2',   '550', 'mailboxfull',     false],
                  ['5.1.1',   '550', 'userunknown',     true]],
      '01009' => [['5.0.912', '',    'hostunknown',     true]],
      '01010' => [['5.0.944', '',    'networkerror',    false]],
      '01011' => [['5.1.1',   '550', 'userunknown',     true]],
      '01012' => [['5.2.2',   '550', 'mailboxfull',     false],
                  ['5.1.1',   '550', 'userunknown',     true]],
      '01013' => [['5.0.912', '',    'hostunknown',     true]],
      '01014' => [['5.0.947', '',    'expired',         false]],
      '01015' => [['5.0.944', '',    'networkerror',    false]],
    }
  end
end

