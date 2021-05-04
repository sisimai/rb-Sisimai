module RhostEngineTest::Public
  module KDDI
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.2.0',   '550', 'filtered',        false]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

