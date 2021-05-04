module LhostEngineTest::Public
  module McAfee
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.911', '550', 'userunknown',     true]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.1.1',   '550', 'userunknown',     true]],
      '04' => [['5.0.911', '550', 'userunknown',     true]],
      '05' => [['5.0.911', '550', 'userunknown',     true]],
    }
  end
end

