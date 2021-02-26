module LhostEngineTest::Private
  module Verizon
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.911', '',    'userunknown',     true]],
      '01002' => [['5.0.911', '550', 'userunknown',     true]],
    }
  end
end

