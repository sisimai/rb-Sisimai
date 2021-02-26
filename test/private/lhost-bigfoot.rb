module LhostEngineTest::Private
  module Bigfoot
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.0',   '554', 'spamdetected',    false]],
      '01002' => [['5.7.1',   '553', 'userunknown',     true]],
    }
  end
end

