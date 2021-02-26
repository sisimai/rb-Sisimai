module RhostEngineTest::Public
  module TencentQQ
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.0',   '550', 'toomanyconn',     false]],
      '02' => [['5.0.0',   '550', 'toomanyconn',     false]],
      '03' => [['5.0.0',   '550', 'blocked',         false]],
    }
  end
end

