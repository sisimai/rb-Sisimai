module LhostEngineTest::Private
  module ApacheJames
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.910', '550', 'filtered',        false]],
      '01002' => [['5.0.910', '550', 'filtered',        false]],
      '01003' => [['5.0.910', '550', 'filtered',        false]],
      '01004' => [['5.0.901', '',    'onhold',          false]],
      '01005' => [['5.0.901', '',    'onhold',          false]],
    }
  end
end

