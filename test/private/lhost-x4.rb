module LhostEngineTest::Private
  module X4
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.922', '',    'mailboxfull',     false]],
      '01002' => [['5.0.922', '',    'mailboxfull',     false]],
      '01003' => [['5.1.2',   '',    'hostunknown',     true]],
      '01004' => [['5.0.922', '',    'mailboxfull',     false]],
      '01005' => [['5.0.911', '550', 'userunknown',     true]],
      '01006' => [['5.1.1',   '',    'userunknown',     true]],
      '01007' => [['5.0.911', '550', 'userunknown',     true]],
      '01008' => [['5.0.911', '550', 'userunknown',     true]],
      '01009' => [['5.1.1',   '',    'userunknown',     true]],
      '01010' => [['5.1.2',   '',    'hostunknown',     true]],
      '01011' => [['5.1.1',   '550', 'userunknown',     true]],
      '01012' => [['5.0.922', '',    'mailboxfull',     false]],
      '01013' => [['5.0.922', '',    'mailboxfull',     false]],
      '01014' => [['5.0.922', '',    'mailboxfull',     false]],
      '01015' => [['5.0.922', '',    'mailboxfull',     false]],
      '01016' => [['5.0.922', '',    'mailboxfull',     false]],
      '01017' => [['4.4.1',   '',    'networkerror',    false]],
      '01018' => [['5.1.1',   '',    'userunknown',     true]],
      '01019' => [['5.0.911', '550', 'userunknown',     true]],
      '01020' => [['5.0.922', '',    'mailboxfull',     false]],
      '01021' => [['4.4.1',   '',    'networkerror',    false]],
      '01022' => [['5.1.1',   '',    'userunknown',     true]],
      '01023' => [['5.0.922', '',    'mailboxfull',     false]],
      '01024' => [['5.0.922', '',    'mailboxfull',     false]],
      '01025' => [['5.1.1',   '',    'userunknown',     true]],
      '01026' => [['5.0.911', '550', 'userunknown',     true]],
      '01027' => [['5.0.922', '',    'mailboxfull',     false]],
    }
  end
end

