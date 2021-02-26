module LhostEngineTest::Public
  module Amavis
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.7.0',   '554', 'spamdetected',    false]],
    }
  end
end

