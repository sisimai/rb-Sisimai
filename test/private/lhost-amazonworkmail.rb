module LhostEngineTest::Private
  module AmazonWorkMail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.2.1',   '550', 'filtered',        false]],
      '01003' => [['5.3.5',   '550', 'systemerror',     false]],
      '01004' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01005' => [['4.4.7',   '421', 'expired',         false]],
      '01006' => [['5.2.2',   '550', 'mailboxfull',     false]],
    }
  end
end

