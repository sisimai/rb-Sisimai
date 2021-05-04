module LhostEngineTest::Private
  module McAfee
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.911', '550', 'userunknown',     true]],
      '01002' => [['5.0.911', '550', 'userunknown',     true]],
      '01003' => [['5.1.1',   '550', 'userunknown',     true]],
      '01004' => [['5.1.1',   '550', 'userunknown',     true]],
      '01005' => [['5.1.1',   '550', 'userunknown',     true]],
      '01006' => [['5.1.1',   '550', 'userunknown',     true]],
      '01007' => [['5.0.911', '550', 'userunknown',     true]],
      '01008' => [['5.0.911', '550', 'userunknown',     true]],
      '01009' => [['5.0.911', '550', 'userunknown',     true]],
    }
  end
end

