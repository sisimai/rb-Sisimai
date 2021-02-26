module LhostEngineTest::Public
  module IMailServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.911', '',    'userunknown',     true]],
      '02' => [['5.0.922', '',    'mailboxfull',     false]],
      '03' => [['5.0.911', '',    'userunknown',     true]],
      '04' => [['5.0.947', '',    'expired',         false]],
      '06' => [['5.0.980', '550', 'spamdetected',    false]],
    }
  end
end

