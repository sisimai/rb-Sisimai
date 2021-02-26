module LhostEngineTest::Public
  module Courier
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.0.0',   '550', 'filtered',        false]],
      '03' => [['5.7.1',   '550', 'blocked',         false]],
      '04' => [['5.0.0',   '',    'hostunknown',     true]],
    }
  end
end

