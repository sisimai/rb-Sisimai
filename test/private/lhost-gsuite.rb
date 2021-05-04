module LhostEngineTest::Private
  module GSuite
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.0',   '550', 'userunknown',     true]],
      '01002' => [['5.0.0',   '',    'userunknown',     true]],
      '01003' => [['5.0.0',   '',    'spamdetected',    false]],
      '01004' => [['5.0.0',   '550', 'filtered',        false]],
      '01005' => [['5.0.0',   '550', 'userunknown',     true]],
      '01006' => [['4.0.0',   '',    'notaccept',       false]],
      '01007' => [['5.1.8',   '501', 'rejected',        false]],
      '01008' => [['4.0.0',   '',    'networkerror',    false]],
      '01009' => [['5.1.1',   '550', 'userunknown',     true]],
      '01010' => [['5.0.0',   '',    'policyviolation', false]],
      '01011' => [['5.0.0',   '553', 'systemerror',     false]],
    }
  end
end

