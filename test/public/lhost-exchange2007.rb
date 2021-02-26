module LhostEngineTest::Public
  module Exchange2007
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '03' => [['5.2.3',   '550', 'mesgtoobig',      false]],
      '04' => [['5.7.1',   '550', 'securityerror',   false]],
      '05' => [['4.4.1',   '441', 'expired',         false]],
      '06' => [['5.1.1',   '550', 'userunknown',     true]],
      '07' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

