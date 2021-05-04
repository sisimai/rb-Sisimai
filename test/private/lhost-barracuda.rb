module LhostEngineTest::Private
  module Barracuda
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.7.1',   '550', 'spamdetected',    false]],
      '01002' => [['5.7.1',   '550', 'spamdetected',    false]],
    }
  end
end

