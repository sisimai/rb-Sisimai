module LhostEngineTest::Private
  module X5
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

