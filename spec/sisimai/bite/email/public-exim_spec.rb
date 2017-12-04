require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Exim'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]7[.]0\z/,      'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.][12][.]1\z/,   'r' => /userunknown/,     'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]7[.]0\z/,      'r' => /policyviolation/, 'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]7[.]0\z/,      'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]1[.]1\z/,      'r' => /userunknown/,     'b' => /\A0\z/ },
  { 'n' => '06', 's' => /\A4[.]0[.]\d+\z/,    'r' => /expired/,         'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A4[.]0[.]\d+\z/,    'r' => /mailboxfull/,     'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A4[.]0[.]\d+\z/,    'r' => /expired/,         'b' => /\A1\z/ },
  { 'n' => '09', 's' => /\A5[.]0[.]\d+\z/,    'r' => /hostunknown/,     'b' => /\A0\z/ },
  { 'n' => '10', 's' => /\A5[.]0[.]\d+\z/,    'r' => /suspend/,         'b' => /\A1\z/ },
  { 'n' => '11', 's' => /\A5[.]0[.]\d+\z/,    'r' => /onhold/,          'b' => /\d\z/ },
  { 'n' => '12', 's' => /\A[45][.]0[.]\d+\z/, 'r' => /(?:hostunknown|expired|undefined)/, 'b' => /\d\z/ },
  { 'n' => '13', 's' => /\A5[.]0[.]\d+\z/,    'r' => /(?:onhold|undefined|mailererror)/,  'b' => /\d\z/ },
  { 'n' => '14', 's' => /\A4[.]0[.]\d+\z/,    'r' => /expired/,         'b' => /\A1\z/ },
  { 'n' => '15', 's' => /\A5[.]4[.]3\z/,      'r' => /systemerror/,     'b' => /\A1\z/ },
  { 'n' => '16', 's' => /\A5[.]0[.]\d+\z/,    'r' => /systemerror/,     'b' => /\A1\z/ },
  { 'n' => '17', 's' => /\A5[.]0[.]\d+\z/,    'r' => /mailboxfull/,     'b' => /\A1\z/ },
  { 'n' => '18', 's' => /\A5[.]0[.]\d+\z/,    'r' => /hostunknown/,     'b' => /\A0\z/ },
  { 'n' => '19', 's' => /\A5[.]0[.]\d+\z/,    'r' => /networkerror/,    'b' => /\A1\z/ },
  { 'n' => '20', 's' => /\A4[.]0[.]\d+\z/,    'r' => /(?:expired|systemerror)/, 'b' => /\A1\z/ },
  { 'n' => '21', 's' => /\A5[.]0[.]\d+\z/,    'r' => /expired/,         'b' => /\A1\z/ },
  { 'n' => '23', 's' => /\A5[.]0[.]\d+\z/,    'r' => /userunknown/,     'b' => /\A0\z/ },
  { 'n' => '24', 's' => /\A5[.]0[.]\d+\z/,    'r' => /filtered/,        'b' => /\A1\z/ },
  { 'n' => '25', 's' => /\A4[.]0[.]\d+\z/,    'r' => /expired/,         'b' => /\A1\z/ },
  { 'n' => '26', 's' => /\A5[.]0[.]0\z/,      'r' => /mailererror/,     'b' => /\A1\z/ },
  { 'n' => '27', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '28', 's' => /\A5[.]0[.]\d+\z/,    'r' => /mailererror/,     'b' => /\A1\z/ },
  { 'n' => '29', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '30', 's' => /\A5[.]7[.]1\z/,      'r' => /userunknown/,     'b' => /\A1\z/ },
  { 'n' => '31', 's' => /\A5[.]0[.]\d+\z/,    'r' => /hostunknown/,     'b' => /\A0\z/ },
  { 'n' => '32', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '33', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '34', 's' => /\A5[.]7[.]1\z/,      'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '35', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '36', 's' => /\A5[.]0[.]\d+\z/,    'r' => /rejected/,        'b' => /\A1\z/ },
  { 'n' => '37', 's' => /\A5[.]0[.]\d+\z/,    'r' => /filtered/,        'b' => /\A1\z/ },
  { 'n' => '38', 's' => /\A4[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '39', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '40', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '41', 's' => /\A4[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '42', 's' => /\A5[.]7[.]1\z/,      'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '43', 's' => /\A5[.]7[.]1\z/,      'r' => /rejected/,        'b' => /\A1\z/ },
  { 'n' => '44', 's' => /\A5[.]0[.]0\z/,      'r' => /mailererror/,     'b' => /\A1\z/ },
  { 'n' => '45', 's' => /\A5[.]2[.]0\z/,      'r' => /rejected/,        'b' => /\A1\z/ },
  { 'n' => '46', 's' => /\A5[.]7[.]1\z/,      'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '47', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '48', 's' => /\A5[.]7[.]1\z/,      'r' => /rejected/,        'b' => /\A1\z/ },
  { 'n' => '49', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '50', 's' => /\A5[.]1[.]7\z/,      'r' => /rejected/,        'b' => /\A1\z/ },
  { 'n' => '51', 's' => /\A5[.]1[.]0\z/,      'r' => /rejected/,        'b' => /\A1\z/ },
  { 'n' => '52', 's' => /\A5[.]0[.]\d+\z/,    'r' => /syntaxerror/,     'b' => /\A1\z/ },
  { 'n' => '53', 's' => /\A5[.]0[.]\d+\z/,    'r' => /mailererror/,     'b' => /\A1\z/ },
  { 'n' => '54', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '55', 's' => /\A5[.]7[.]0\z/,      'r' => /spamdetected/,    'b' => /\A1\z/ },
  { 'n' => '56', 's' => /\A5[.]0[.]\d+\z/,    'r' => /blocked/,         'b' => /\A1\z/ },
  { 'n' => '57', 's' => /\A5[.]0[.]\d+\z/,    'r' => /rejected/,        'b' => /\A1\z/ },
  { 'n' => '58', 's' => /\A5[.]0[.]\d+\z/,    'r' => /mesgtoobig/,      'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

