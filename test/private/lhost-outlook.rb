module LhostEngineTest::Private
  module Outlook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01002' => [['5.5.0',   '550', 'userunknown',     true]],
      '01003' => [['5.5.0',   '550', 'userunknown',     true]],
      '01007' => [['5.5.0',   '550', 'blocked',         false]],
      '01008' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '01016' => [['5.2.2',   '550', 'mailboxfull',     false]],
      '01017' => [['5.1.1',   '550', 'userunknown',     true]],
      '01018' => [['5.5.0',   '554', 'hostunknown',     true]],
      '01019' => [['5.1.1',   '550', 'userunknown',     true],
                  ['5.2.2',   '550', 'mailboxfull',     false]],
      '01023' => [['5.1.1',   '550', 'userunknown',     true]],
      '01024' => [['5.1.1',   '550', 'userunknown',     true]],
      '01025' => [['5.5.0',   '550', 'filtered',        false]],
      '01026' => [['5.5.0',   '550', 'filtered',        false]],
      '01027' => [['5.5.0',   '550', 'userunknown',     true]],
    }
  end
end

