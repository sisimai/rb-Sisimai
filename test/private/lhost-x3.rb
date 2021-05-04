module LhostEngineTest::Private
  module X3
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.3.0',   '553', 'userunknown',     true]],
      '01002' => [['5.0.900', '',    'undefined',       false]],
      '01003' => [['5.0.947', '',    'expired',         false]],
      '01004' => [['5.3.0',   '553', 'userunknown',     true]],
      '01005' => [['5.0.900', '',    'undefined',       false]],
      '01006' => [['5.3.0',   '553', 'userunknown',     true]],
      '01007' => [['5.0.947', '',    'expired',         false]],
      '01008' => [['5.3.0',   '553', 'userunknown',     true]],
    }
  end
end

