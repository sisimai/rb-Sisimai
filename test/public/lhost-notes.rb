module LhostEngineTest::Public
  module Notes
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.901', '',    'onhold',          false]],
      '02' => [['5.0.911', '',    'userunknown',     true]],
      '03' => [['5.0.911', '',    'userunknown',     true]],
    }
  end
end

