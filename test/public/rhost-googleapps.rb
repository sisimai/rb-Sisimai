module RhostEngineTest::Public
  module GoogleApps
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.2.1',   '550', 'suspend',         false]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

