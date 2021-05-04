module LhostEngineTest::Public
  module MailMarshalSMTP
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

