module LhostEngineTest::Private
  module X1
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.910', '',    'filtered',        false]],
      '01002' => [['5.0.910', '',    'filtered',        false],
                  ['5.0.910', '',    'filtered',        false]],
      '01003' => [['5.0.910', '',    'filtered',        false]],
      '01004' => [['5.0.910', '',    'filtered',        false]],
      '01005' => [['5.0.910', '',    'filtered',        false]],
    }
  end
end

