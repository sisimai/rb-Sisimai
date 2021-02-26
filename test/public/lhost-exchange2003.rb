module LhostEngineTest::Public
  module Exchange2003
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.911', '',    'userunknown',     true]],
      '02' => [['5.0.911', '',    'userunknown',     true],
               ['5.0.911', '',    'userunknown',     true]],
      '03' => [['5.0.911', '',    'userunknown',     true]],
      '04' => [['5.0.910', '',    'filtered',        false]],
      '05' => [['5.0.911', '',    'userunknown',     true]],
      '07' => [['5.0.911', '',    'userunknown',     true]],
    }
  end
end

