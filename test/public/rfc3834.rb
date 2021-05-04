module LhostEngineTest::Public
  module RFC3834
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['', '', 'vacation', false]],
      '02' => [['', '', 'vacation', false]],
      '03' => [['', '', 'vacation', false]],
      '04' => [['', '', 'vacation', false]],
    }
  end
end

