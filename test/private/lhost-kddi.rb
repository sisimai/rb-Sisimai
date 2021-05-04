module LhostEngineTest::Private
  module KDDI
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.922', '',    'mailboxfull',     false]],
      '01002' => [['5.0.922', '',    'mailboxfull',     false]],
      '01003' => [['5.0.922', '',    'mailboxfull',     false]],
    }
  end
end

