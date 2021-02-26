module LhostEngineTest::Public
  module EinsUndEins
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '02' => [['5.0.934', '',    'mesgtoobig',      false]],
      '03' => [['5.2.0',   '550', 'spamdetected',    false]],
    }
  end
end

