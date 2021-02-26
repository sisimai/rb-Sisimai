module LhostEngineTest::Public
  module X4
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.922', '',    'mailboxfull',     false]],
      '08' => [['4.4.1',   '',    'networkerror',    false]],
    }
  end
end

