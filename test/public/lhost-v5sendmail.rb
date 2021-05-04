module LhostEngineTest::Public
  module V5sendmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.947', '',    'expired',         false]],
      '02' => [['5.0.912', '550', 'hostunknown',     true]],
      '03' => [['5.0.911', '550', 'userunknown',     true]],
      '04' => [['5.0.912', '550', 'hostunknown',     true],
               ['5.0.912', '550', 'hostunknown',     true]],
      '05' => [['5.0.971', '550', 'blocked',         false],
               ['5.0.912', '550', 'hostunknown',     true],
               ['5.0.912', '550', 'hostunknown',     true],
               ['5.0.911', '550', 'userunknown',     true]],
      '06' => [['5.0.909', '550', 'norelaying',      false]],
      '07' => [['5.0.971', '501', 'blocked',         false],
               ['5.0.912', '550', 'hostunknown',     true],
               ['5.0.911', '550', 'userunknown',     true]],
    }
  end
end

