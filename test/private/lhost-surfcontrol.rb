module LhostEngineTest::Private
  module SurfControl
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.0',   '550', 'filtered',        false]],
      '01002' => [['5.0.0',   '550', 'filtered',        false]],
      '01003' => [['5.0.0',   '550', 'filtered',        false]],
      '01004' => [['5.0.0',   '554', 'systemerror',     false]],
      '01005' => [['5.0.0',   '554', 'systemerror',     false]],
    }
  end
end

