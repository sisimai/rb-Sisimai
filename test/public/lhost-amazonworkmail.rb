module LhostEngineTest::Public
  module AmazonWorkMail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.1',   '550', 'filtered',        false]],
      '03' => [['5.3.5',   '550', 'systemerror',     false]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '05' => [['4.4.7',   '421', 'expired',         false]],
      '07' => [['4.4.7',   '421', 'expired',         false]],
      '08' => [['5.2.2',   '550', 'mailboxfull',     false]],
    }
  end
end

