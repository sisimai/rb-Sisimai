module LhostEngineTest::Private
  module PowerMTA
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.0',   '554', 'userunknown',     true]],
      '01002' => [['5.2.1',   '550', 'userunknown',     true]],
    }
  end
end

