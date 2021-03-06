require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'PowerMTA'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]2[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]0\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]2[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

