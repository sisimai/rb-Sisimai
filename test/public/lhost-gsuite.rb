module LhostEngineTest::Public
  module GSuite
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.0',   '550', 'userunknown',     true]],
      '02' => [['5.0.0',   '',    'userunknown',     true]],
      '03' => [['4.0.0',   '',    'notaccept',       false]],
      '04' => [['4.0.0',   '',    'networkerror',    false]],
      '05' => [['4.0.0',   '',    'networkerror',    false]],
      '06' => [['4.4.1',   '',    'expired',         false]],
      '07' => [['4.4.1',   '',    'expired',         false]],
      '08' => [['5.0.0',   '550', 'filtered',        false]],
      '09' => [['5.0.0',   '550', 'userunknown',     true]],
      '10' => [['4.0.0',   '',    'notaccept',       false]],
      '11' => [['5.1.8',   '501', 'rejected',        false]],
      '12' => [['5.0.0',   '',    'spamdetected',    false]],
      '13' => [['4.0.0',   '',    'networkerror',    false]],
      '14' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

