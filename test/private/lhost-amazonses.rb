module LhostEngineTest::Private
  module AmazonSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01002' => [['5.2.1',   '550', 'filtered',        false]],
      '01003' => [['5.1.1',   '550', 'userunknown',     true]],
      '01004' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01005' => [['5.7.1',   '550', 'securityerror',   false]],
      '01006' => [['5.1.1',   '550', 'userunknown',     true]],
      '01007' => [['5.4.7',   '',    'expired',         false]],
      '01008' => [['5.1.2',   '',    'hostunknown',     true]],
      '01009' => [['5.1.0',   '550', 'userunknown',     true]],
      '01010' => [['5.1.0',   '550', 'userunknown',     true]],
      '01011' => [['5.1.0',   '550', 'userunknown',     true]],
      '01012' => [['5.1.0',   '550', 'userunknown',     true]],
      '01013' => [['5.1.0',   '550', 'userunknown',     true]],
      '01014' => [['5.3.0',   '550', 'filtered',        false]],
      '01015' => [['5.1.1',   '550', 'userunknown',     true]],
      '01016' => [['',        '',    'feedback',        false, 'abuse']],
      '01017' => [['2.6.0',   '250', 'delivered',       false]],
      '01018' => [['2.6.0',   '250', 'delivered',       false]],
      '01019' => [['5.7.1',   '554', 'blocked',         false]],
      '01020' => [['4.4.7',   '',    'expired',         false]],
      '01021' => [['5.4.4',   '550', 'hostunknown',     true]],
      '01022' => [['5.5.1',   '550', 'blocked',         false]],
      '01023' => [['5.7.1',   '550', 'suspend',         false]],
      '01024' => [['5.4.1',   '550', 'filtered',        false]],
      '01025' => [['5.2.1',   '550', 'suspend',         false]],
      '01026' => [['5.7.1',   '554', 'norelaying',      false]],
      '01027' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '01028' => [['5.4.7',   '',    'expired',         false]],
      '01029' => [['5.3.0',   '550', 'filtered',        false]],
      '01030' => [['2.6.0',   '250', 'delivered',       false]],
      '01031' => [['2.6.0',   '250', 'delivered',       false]],
    }
  end
end

