module LhostEngineTest::Public
  module EZweb
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.910', '',    'filtered',        false]],
      '02' => [['5.0.0',   '',    'suspend',         false]],
      '03' => [['5.0.921', '',    'suspend',         false]],
      '04' => [['5.0.911', '550', 'userunknown',     true]],
      '05' => [['5.0.947', '',    'expired',         false]],
      '07' => [['5.0.911', '550', 'userunknown',     true]],
      '08' => [['5.0.971', '550', 'blocked',         false]],
    }
  end
end

