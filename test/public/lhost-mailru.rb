module LhostEngineTest::Public
  module MailRu
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '03' => [['5.2.2',   '550', 'mailboxfull',     false],
               ['5.2.1',   '550', 'userunknown',     true]],
      '04' => [['5.1.1',   '550', 'userunknown',     true]],
      '05' => [['5.0.932', '',    'notaccept',       true]],
      '06' => [['5.0.912', '',    'hostunknown',     true]],
      '07' => [['5.0.910', '550', 'filtered',        false]],
      '08' => [['5.0.911', '550', 'userunknown',     true]],
      '09' => [['5.1.8',   '501', 'rejected',        false]],
      '10' => [['5.0.947', '',    'expired',         false]],
    }
  end
end

