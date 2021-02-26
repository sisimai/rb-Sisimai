module LhostEngineTest::Public
  module Outlook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.5.0',   '554', 'hostunknown',     true]],
      '04' => [['5.1.1',   '550', 'userunknown',     true],
               ['5.2.2',   '550', 'mailboxfull',     false]],
      '06' => [['4.4.7',   '',    'expired',         false]],
      '07' => [['4.4.7',   '',    'expired',         false]],
      '08' => [['5.5.0',   '550', 'userunknown',     true]],
      '09' => [['5.5.0',   '550', 'blocked',         false]],
    }
  end
end

