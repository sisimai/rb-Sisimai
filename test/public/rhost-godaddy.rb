module RhostEngineTest::Public
  module GoDaddy
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '02' => [['5.1.3',   '553', 'blocked',         false]],
      '03' => [['5.1.1',   '550', 'toomanyconn',     false]],
    }
  end
end

