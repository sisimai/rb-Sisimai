module LhostEngineTest::Public
  module SurfControl
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.0',   '550', 'filtered',        false]],
      '02' => [['5.0.0',   '554', 'systemerror',     false]],
      '03' => [['5.0.0',   '554', 'systemerror',     false]],
    }
  end
end

