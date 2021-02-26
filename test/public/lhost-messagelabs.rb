module LhostEngineTest::Public
  module MessageLabs
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.0',   '550', 'securityerror',   false]],
      '02' => [['5.0.0',   '550', 'userunknown',     true]],
      '03' => [['5.0.0',   '542', 'userunknown',     true]],
    }
  end
end

