module LhostEngineTest::Public
  module Domino
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.911', '',    'userunknown',     true]],
      '02' => [['5.0.0',   '',    'userunknown',     true]],
      '03' => [['5.0.0',   '',    'networkerror',    false]],
    }
  end
end

