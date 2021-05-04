module LhostEngineTest::Public
  module AmazonSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.7.1',   '550', 'securityerror',   false]],
      '02' => [['5.3.0',   '550', 'filtered',        false]],
      '03' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '05' => [['5.1.1',   '550', 'userunknown',     true]],
      '06' => [['5.1.1',   '550', 'userunknown',     true]],
      '07' => [['5.7.6',   '550', 'securityerror',   false]],
      '08' => [['5.7.9',   '550', 'securityerror',   false]],
      '09' => [['5.1.1',   '550', 'userunknown',     true]],
      '10' => [['5.1.1',   '550', 'userunknown',     true]],
      '11' => [['',        '',    'feedback',        false, 'abuse']],
      '12' => [['2.6.0',   '250', 'delivered',       false]],
      '13' => [['2.6.0',   '250', 'delivered',       false]],
      '14' => [['5.7.1',   '554', 'blocked',         false]],
      '15' => [['5.7.1',   '554', 'blocked',         false]],
      '16' => [['5.7.1',   '521', 'blocked',         false]],
      '17' => [['4.4.7',   '',    'expired',         false]],
      '18' => [['5.4.4',   '550', 'hostunknown',     true]],
      '19' => [['5.7.1',   '550', 'suspend',         false]],
      '20' => [['5.2.1',   '550', 'suspend',         false]],
      '21' => [['5.7.1',   '554', 'norelaying',      false]],
    }
  end
end

