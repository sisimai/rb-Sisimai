module LhostEngineTest::Public
  module Barracuda
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.7.1',   '550', 'spamdetected',    false]],
      '02' => [['5.7.1',   '550', 'spamdetected',    false]],
    }
  end
end

