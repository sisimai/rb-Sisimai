module LhostEngineTest::Public
  module Zoho
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.1',   '550', 'filtered',        false],
               ['5.2.2',   '550', 'mailboxfull',     false]],
      '03' => [['5.0.910', '550', 'filtered',        false]],
      '04' => [['4.0.947', '421', 'expired',         false]],
      '05' => [['4.0.947', '421', 'expired',         false]],
    }
  end
end

