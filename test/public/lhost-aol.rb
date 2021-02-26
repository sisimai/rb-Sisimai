module LhostEngineTest::Public
  module Aol
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.4.4',   '',    'hostunknown',     true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '03' => [['5.2.2',   '550', 'mailboxfull',     false],
               ['5.1.1',   '550', 'userunknown',     true]],
      '04' => [['5.1.1',   '550', 'userunknown',     true]],
      '05' => [['5.4.4',   '',    'hostunknown',     true]],
      '06' => [['5.4.4',   '',    'notaccept',       true]],}
  end
end

