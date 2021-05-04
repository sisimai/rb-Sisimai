module LhostEngineTest::Private
  module Courier
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.0',   '550', 'filtered',        false]],
      '01002' => [['5.0.0',   '550', 'filtered',        false]],
      '01003' => [['5.7.1',   '550', 'blocked',         false]],
      '01004' => [['5.0.0',   '550', 'userunknown',     true]],
      '01005' => [['5.1.1',   '550', 'userunknown',     true]],
      '01006' => [['5.1.1',   '550', 'userunknown',     true]],
      '01007' => [['5.0.0',   '550', 'userunknown',     true]],
      '01008' => [['5.1.1',   '550', 'userunknown',     true]],
      '01009' => [['5.0.0',   '550', 'filtered',        false]],
      '01010' => [['5.7.1',   '550', 'blocked',         false]],
      '01011' => [['5.0.0',   '',    'hostunknown',     true]],
      '01012' => [['5.0.0',   '',    'hostunknown',     true]],
    }
  end
end

