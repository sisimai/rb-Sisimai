module LhostEngineTest::Public
  module MFILTER
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.910', '550', 'filtered',        false]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.0.910', '550', 'filtered',        false]],
      '04' => [['5.4.1',   '550', 'rejected',        false]],
    }
  end
end

