module LhostEngineTest::Private
  module MessageLabs
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.0.0',   '550', 'securityerror',   false]],
      '01003' => [['5.0.0',   '542', 'userunknown',     true]],
      '01004' => [['5.0.0',   '550', 'userunknown',     true]],
    }
  end
end

