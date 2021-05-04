module LhostEngineTest::Private
  module Zoho
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',     true]],
      '01002' => [['5.2.1',   '550', 'filtered',        false],
                  ['5.2.2',   '550', 'mailboxfull',     false]],
      '01003' => [['5.0.910', '550', 'filtered',        false]],
      '01004' => [['4.0.947', '421', 'expired',         false]],
    }
  end
end

