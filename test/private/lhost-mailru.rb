module LhostEngineTest::Private
  module MailRu
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.911', '',    'userunknown',     true]],
      '01002' => [['5.1.1',   '550', 'userunknown',     true]],
      '01003' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01004' => [['5.2.2',   '550', 'mailboxfull',     false],
                  ['5.2.1',   '550', 'userunknown',     true]],
      '01005' => [['5.0.910', '',    'filtered',        false]],
      '01006' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01007' => [['5.0.911', '',    'userunknown',     true]],
      '01008' => [['5.1.1',   '550', 'userunknown',     true]],
      '01009' => [['5.0.910', '550', 'filtered',        false]],
      '01010' => [['5.0.911', '550', 'userunknown',     true]],
      '01011' => [['5.1.8',   '501', 'rejected',        false]],
    }
  end
end

