module LhostEngineTest::Private
  module MFILTER
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.910', '550', 'filtered',        false]],
      '01002' => [['5.1.1',   '550', 'userunknown',     true]],
      '01003' => [['5.0.910', '550', 'filtered',        false]],
      '01004' => [['5.0.910', '550', 'filtered',        false]],
      '01005' => [['5.1.1',   '550', 'userunknown',     true]],
      '01006' => [['5.0.910', '550', 'filtered',        false]],
      '01007' => [['5.0.910', '550', 'filtered',        false]],
      '01008' => [['5.4.1',   '550', 'rejected',        false]],
      '01009' => [['5.4.1',   '550', 'rejected',        false]],
    }
  end
end

