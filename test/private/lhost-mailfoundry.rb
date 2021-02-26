module LhostEngineTest::Private
  module MailFoundry
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.910', '550', 'filtered',        false]],
      '01002' => [['5.1.1',   '552', 'mailboxfull',     false]],
      '01003' => [['5.1.1',   '550', 'userunknown',     true]],
      '01004' => [['5.0.910', '550', 'filtered',        false]],
      '01005' => [['5.1.1',   '552', 'mailboxfull',     false]],
    }
  end
end

