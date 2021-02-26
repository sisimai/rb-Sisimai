module LhostEngineTest::Public
  module X6
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.4.6',   '554', 'networkerror',    false]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

