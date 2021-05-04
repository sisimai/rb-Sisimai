module LhostEngineTest::Public
  module KDDI
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.922', '',    'mailboxfull',     false]],
      '02' => [['5.0.922', '',    'mailboxfull',     false]],
      '03' => [['5.0.922', '',    'mailboxfull',     false]],
    }
  end
end

