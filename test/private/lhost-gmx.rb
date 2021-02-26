module LhostEngineTest::Private
  module GMX
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.947', '',    'expired',         false]],
      '01002' => [['5.1.1',   '',    'userunknown',     true]],
      '01003' => [['5.2.2',   '',    'mailboxfull',     false]],
      '01004' => [['5.2.1',   '',    'userunknown',     true],
                  ['5.2.2',   '',    'mailboxfull',     false]],
    }
  end
end

