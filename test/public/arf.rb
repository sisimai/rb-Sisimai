module LhostEngineTest::Public
  module ARF
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['', '', 'feedback', false, 'abuse'       ]],
      '02' => [['', '', 'feedback', false, 'abuse'       ]],
      '11' => [['', '', 'feedback', false, 'abuse'       ]],
      '12' => [['', '', 'feedback', false, 'opt-out'     ]],
      '14' => [['', '', 'feedback', false, 'abuse'       ]],
      '15' => [['', '', 'feedback', false, 'abuse'       ]],
      '16' => [['', '', 'feedback', false, 'abuse'       ],
               ['', '', 'feedback', false, 'abuse'       ],
               ['', '', 'feedback', false, 'abuse'       ],
               ['', '', 'feedback', false, 'abuse'       ],
               ['', '', 'feedback', false, 'abuse'       ],
               ['', '', 'feedback', false, 'abuse'       ],
               ['', '', 'feedback', false, 'abuse'       ]],
      '17' => [['', '', 'feedback', false, 'abuse'       ],
               ['', '', 'feedback', false, 'abuse'       ]],
      '18' => [['', '', 'feedback', false, 'auth-failure']],
      '19' => [['', '', 'feedback', false, 'auth-failure']],
      '20' => [['', '', 'feedback', false, 'auth-failure']],
      '21' => [['', '', 'feedback', false, 'abuse'       ]],
      '22' => [['', '', 'feedback', false, 'abuse'       ]],
      '23' => [['', '', 'feedback', false, 'abuse'       ]],
      '24' => [['', '', 'feedback', false, 'abuse'       ]],
      '25' => [['', '', 'feedback', false, 'abuse'       ]],
    }
  end
end


