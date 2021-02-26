module LhostEngineTest::Public
  module MailFoundry
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.910', '550', 'filtered',        false]],
      '02' => [['5.1.1',   '552', 'mailboxfull',     false]],
    }
  end
end

