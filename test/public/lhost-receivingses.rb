module LhostEngineTest::Public
  module ReceivingSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'filtered',        false]],
      '02' => [['5.1.1',   '550', 'filtered',        false]],
      '03' => [['4.0.0',   '450', 'onhold',          false]],
      '04' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '05' => [['5.3.4',   '552', 'mesgtoobig',      false]],
      '06' => [['5.6.1',   '500', 'contenterror',    false]],
      '07' => [['5.2.0',   '550', 'filtered',        false]],
    }
  end
end

