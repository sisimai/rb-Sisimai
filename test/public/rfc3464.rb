module LhostEngineTest::Public
  module RFC3464
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '',    'mailboxfull',     false]],
      '03' => [['5.0.0',   '554', 'policyviolation', false]],
      '04' => [['5.5.0',   '554', 'mailererror',     false]],
      '06' => [['5.5.0',   '',    'userunknown',     true]],
      '07' => [['4.4.0',   '',    'expired',         false]],
      '08' => [['5.7.1',   '550', 'spamdetected',    false]],
      '09' => [['4.3.0',   '',    'mailboxfull',     false]],
      '10' => [['5.1.6',   '550', 'hasmoved',        true]],
      '26' => [['5.1.1',   '550', 'userunknown',     true]],
      '28' => [['2.1.5',   '250', 'delivered',       false],
               ['2.1.5',   '250', 'delivered',       false]],
      '29' => [['5.5.0',   '503', 'syntaxerror',     false]],
      '34' => [['4.4.1',   '',    'networkerror',    false]],
      '35' => [['5.0.0',   '550', 'rejected',        false],
               ['4.0.0',   '',    'expired',         false],
               ['5.0.0',   '550', 'filtered',        false]],
      '36' => [['4.0.0',   '426', 'expired',         false]],
      '37' => [['5.0.912', '',    'hostunknown',     true]],
      '38' => [['5.0.922', '',    'mailboxfull',     false]],
      '39' => [['5.0.901', '',    'onhold',          false]],
      '40' => [['4.4.6',   '',    'networkerror',    false]],
    }
  end
end

