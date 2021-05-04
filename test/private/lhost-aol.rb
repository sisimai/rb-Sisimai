module LhostEngineTest::Private
  module Aol
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.4.4',   '',    'hostunknown',     true]],
      '01002' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01003' => [['5.2.2',   '550', 'mailboxfull',     false],
                  ['5.1.1',   '550', 'userunknown',     true]],
      '01004' => [['5.2.2',   '550', 'mailboxfull',     false],
                  ['5.1.1',   '550', 'userunknown',     true]],
      '01005' => [['5.1.1',   '550', 'userunknown',     true]],
      '01006' => [['5.1.1',   '550', 'userunknown',     true]],
      '01007' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '01008' => [['5.7.1',   '554', 'filtered',        false]],
      '01009' => [['5.7.1',   '554', 'policyviolation', false]],
      '01010' => [['5.7.1',   '554', 'filtered',        false]],
      '01011' => [['5.7.1',   '554', 'filtered',        false]],
      '01012' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '01013' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '01014' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

