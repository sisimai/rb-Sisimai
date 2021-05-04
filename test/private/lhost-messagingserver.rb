module LhostEngineTest::Private
  module MessagingServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.4.4',   '',    'hostunknown',     true]],
      '01002' => [['5.0.0',   '',    'mailboxfull',     false]],
      '01003' => [['5.7.1',   '550', 'filtered',        false],
                  ['5.7.1',   '550', 'filtered',        false]],
      '01004' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01005' => [['5.4.4',   '',    'hostunknown',     true]],
      '01006' => [['5.7.1',   '550', 'filtered',        false]],
      '01007' => [['5.2.0',   '522', 'mailboxfull',     false]],
      '01008' => [['5.2.1',   '550', 'filtered',        false]],
      '01009' => [['5.0.0',   '',    'mailboxfull',     false]],
      '01010' => [['5.2.0',   '522', 'mailboxfull',     false]],
      '01011' => [['4.4.7',   '',    'expired',         false]],
      '01012' => [['5.0.0',   '550', 'filtered',        false]],
      '01013' => [['4.2.2',   '',    'mailboxfull',     false]],
      '01014' => [['4.2.2',   '',    'mailboxfull',     false]],
      '01015' => [['5.0.0',   '550', 'filtered',        false]],
      '01016' => [['5.0.0',   '550', 'userunknown',     true]],
      '01017' => [['5.0.932', '',    'notaccept',       true]],
      '01018' => [['5.1.8',   '501', 'rejected',        false]],
      '01019' => [['4.2.2',   '',    'mailboxfull',     false]],
    }
  end
end

