module LhostEngineTest::Private
  module Activehunter
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.910', '550', 'filtered',        false]],
      '01002' => [['5.1.1',   '550', 'userunknown',     true]],
      '01003' => [['5.0.910', '553', 'filtered',        false]],
      '01004' => [['5.7.17',  '550', 'filtered',        false]],
      '01005' => [['5.1.1',   '550', 'userunknown',     true]],
      '01006' => [['5.1.1',   '550', 'userunknown',     true]],
      '01007' => [['5.0.910', '550', 'filtered',        false]],
      '01008' => [['5.0.910', '550', 'filtered',        false]],
      '01009' => [['5.1.1',   '550', 'userunknown',     true]],
      '01010' => [['5.0.910', '553', 'filtered',        false]],
      '01011' => [['5.7.17',  '550', 'filtered',        false]],
      '01012' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

