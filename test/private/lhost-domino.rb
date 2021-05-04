module LhostEngineTest::Private
  module Domino
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.0',   '',    'onhold',          false]],
      '01002' => [['5.1.1',   '',    'userunknown',     true]],
      '01003' => [['5.0.0',   '',    'userunknown',     true]],
      '01004' => [['5.0.0',   '',    'userunknown',     true]],
      '01005' => [['5.0.0',   '',    'onhold',          false]],
      '01006' => [['5.0.911', '',    'userunknown',     true]],
      '01007' => [['5.0.0',   '',    'userunknown',     true]],
      '01008' => [['5.0.911', '',    'userunknown',     true]],
      '01009' => [['5.0.911', '',    'userunknown',     true]],
      '01010' => [['5.0.911', '',    'userunknown',     true]],
      '01011' => [['5.1.1',   '',    'userunknown',     true]],
      '01012' => [['5.0.911', '',    'userunknown',     true]],
      '01013' => [['5.0.911', '',    'userunknown',     true]],
      '01014' => [['5.0.911', '',    'userunknown',     true]],
      '01015' => [['5.0.0',   '',    'networkerror',    false]],
      '01016' => [['5.0.0',   '',    'systemerror',     false]],
      '01017' => [['5.0.0',   '',    'userunknown',     true]],
      '01018' => [['5.1.1',   '',    'userunknown',     true]],
      '01019' => [['5.0.0',   '',    'userunknown',     true]],
    }
  end
end

