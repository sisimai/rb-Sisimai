module LhostEngineTest::Private
  module Office365
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.10',  '550', 'userunknown',     true]],
      '01002' => [['5.1.10',  '550', 'userunknown',     true]],
      '01003' => [['5.1.10',  '550', 'userunknown',     true]],
      '01004' => [['5.1.10',  '550', 'userunknown',     true]],
      '01005' => [['5.1.10',  '550', 'userunknown',     true]],
      '01006' => [['5.4.14',  '554', 'networkerror',    false]],
      '01007' => [['5.1.1',   '550', 'userunknown',     true]],
      '01008' => [['5.1.1',   '550', 'userunknown',     true]],
      '01009' => [['5.0.0',   '553', 'securityerror',   false]],
      '01010' => [['5.1.0',   '550', 'blocked',         false]],
      '01011' => [['5.1.351', '550', 'filtered',        false]],
      '01012' => [['5.1.8',   '501', 'rejected',        false]],
      '01013' => [['5.4.312', '550', 'networkerror',    false]],
      '01014' => [['5.1.351', '550', 'userunknown',     true]],
      '01015' => [['5.1.351', '550', 'userunknown',     true]],
      '01016' => [['5.1.1',   '550', 'userunknown',     true]],
      '01017' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01018' => [['5.1.10',  '550', 'userunknown',     true]],
      '01019' => [['5.1.10',  '550', 'userunknown',     true]],
      '01020' => [['5.1.10',  '550', 'userunknown',     true]],
      '01021' => [['5.4.14',  '554', 'networkerror',    false]],
      '01022' => [['5.2.14',  '550', 'systemerror',     false]],
      '01023' => [['5.4.310', '550', 'systemerror',     false]],
      '01024' => [['5.4.310', '550', 'systemerror',     false]],
      '01025' => [['5.1.10',  '550', 'userunknown',     true]],
      '01026' => [['5.1.10',  '550', 'userunknown',     true]],
      '01027' => [['5.1.1',   '550', 'userunknown',     true]],
      '01028' => [['5.1.1',   '550', 'userunknown',     true]],
      '01029' => [['5.1.1',   '550', 'userunknown',     true]],
      '01030' => [['5.2.3',   '550', 'exceedlimit',     false]],
      '01031' => [['5.1.10',  '550', 'userunknown',     true]],
    }
  end
end

