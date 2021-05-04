module LhostEngineTest::Private
  module Yahoo
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01003' => [['5.2.1',   '550', 'userunknown',     true]],
      '01004' => [['5.1.1',   '550', 'userunknown',     true]],
      '01005' => [['5.0.971', '554', 'blocked',         false]],
      '01006' => [['5.0.911', '550', 'userunknown',     true]],
      '01007' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01008' => [['5.0.932', '',    'notaccept',       true]],
      '01009' => [['5.1.1',   '550', 'userunknown',     true]],
      '01010' => [['5.1.8',   '501', 'rejected',        false]],
      '01011' => [['5.0.971', '554', 'blocked',         false]],
    }
  end
end

