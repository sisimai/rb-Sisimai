require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'McAfee'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /userunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

