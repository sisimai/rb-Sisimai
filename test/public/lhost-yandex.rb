module LhostEngineTest::Public
  module Yandex
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.1',   '550', 'userunknown',     true],
               ['5.2.2',   '550', 'mailboxfull',     false]],
      '03' => [['4.4.1',   '',    'expired',         false]],
    }
  end
end

