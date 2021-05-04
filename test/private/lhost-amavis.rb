module LhostEngineTest::Private
  module Amavis
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.1.1',   '550', 'userunknown',     true]],
      '01003' => [['5.7.0',   '554', 'spamdetected',    false]],
    }
  end
end

