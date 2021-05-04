module LhostEngineTest::Private
  module Facebook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'filtered',        false]],
      '01002' => [['5.1.1',   '550', 'filtered',        false]],
      '01003' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

