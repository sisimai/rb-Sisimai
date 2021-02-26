module LhostEngineTest::Public
  module Office365
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.10',  '550', 'userunknown',     true]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.1.0',   '550', 'blocked',         false]],
      '04' => [['5.1.351', '550', 'filtered',        false]],
      '05' => [['5.1.8',   '501', 'rejected',        false]],
      '06' => [['5.4.312', '550', 'networkerror',    false]],
      '07' => [['5.1.351', '550', 'userunknown',     true]],
      '08' => [['5.4.316', '550', 'expired',         false]],
      '09' => [['5.1.351', '550', 'userunknown',     true]],
      '10' => [['5.1.351', '550', 'userunknown',     true]],
      '11' => [['5.1.1',   '550', 'userunknown',     true]],
      '12' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '13' => [['5.1.10',  '550', 'userunknown',     true]],
    }
  end
end

