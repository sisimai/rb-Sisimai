module LhostEngineTest::Public
  module Qmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.5.0',   '550', 'userunknown',     true]],
      '02' => [['5.1.1',   '550', 'userunknown',     true],
               ['5.2.1',   '550', 'userunknown',     true]],
      '03' => [['5.7.1',   '550', 'rejected',        false]],
      '04' => [['5.0.0',   '501', 'blocked',         false]],
      '05' => [['4.4.3',   '',    'systemerror',     false]],
      '06' => [['4.2.2',   '450', 'mailboxfull',     false]],
      '07' => [['4.4.1',   '',    'networkerror',    false]],
      '08' => [['5.0.922', '552', 'mailboxfull',     false]],
      '09' => [['5.7.606', '550', 'blocked',         false]],
      '10' => [['5.0.921', '',    'suspend',         false]],
    }
  end
end

