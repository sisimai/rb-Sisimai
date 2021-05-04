module LhostEngineTest::Private
  module SendGrid
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.1.1',   '550', 'userunknown',     true]],
      '01003' => [['5.0.947', '',    'expired',         false]],
      '01004' => [['5.0.0',   '550', 'filtered',        false]],
      '01005' => [['5.2.1',   '550', 'userunknown',     true]],
      '01006' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01007' => [['5.1.1',   '550', 'userunknown',     true]],
      '01008' => [['5.0.0',   '554', 'filtered',        false]],
      '01009' => [['5.0.0',   '550', 'userunknown',     true]],
    }
  end
end

