module LhostEngineTest::Private
  module Yandex
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.2.1',   '550', 'userunknown',     true],
                  ['5.2.2',   '550', 'mailboxfull',     false]],
    }
  end
end

