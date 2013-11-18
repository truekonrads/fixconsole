RSpec.configure do |config|
  config.mock_framework = :mocha
end
require_relative '../lib/fix.rb'

FIXMSG1="8=FIXT.1.1\x019=121\x0135=A\x0149=GSED018437\x0156=TR MATCHING\x0134=3884\x01142=TRFXMAB1234567890\x0152=20131118-14:48:16\x0198=0\x01108=4\x01789=3817\x011137=9\x011407=100\x0110=034\x01"

FIXMSG1_EXPANDED={
	8 => "FIXT.1.1",
	9 => "121",
	35 => "A",
	49 => "GSED018437",
	56 => "TR MATCHING",
	34 => "3884",
	142 => "TRFXMAB1234567890",
	52 => "20131118-14:48:16",
	98 => "0",
	108 => "4",
	789 => "3817",
	1137 => "9",
	1407 => "100",
	10 => "034",
}

describe Fix::FixMessage, "#checksum" do
	it "calculates a correct checksum" do
		m=Fix::FixMessage.from_fix(FIXMSG1)
		m.checksum(m._fix_wo_checksum).should eq("034") 
	end 
end 

describe Fix::FixMessage, "#from_fix" do
	it "parses fix message correctly" do
		m=Fix::FixMessage.from_fix(FIXMSG1)
		m.tags.should == FIXMSG1_EXPANDED
		#puts m
		#puts FIXMSG1_EXPANDED 
	end 
end 

describe Fix::FixMessage, "#to_fix" do
	it "serialises fix message correctly" do
		orig=Fix::FixMessage.from_fix(FIXMSG1)
		hobbit=Fix::FixMessage.from_fix(orig.to_fix)
		orig.tags.should == hobbit.tags
		#puts m
		#puts FIXMSG1_EXPANDED 
	end 
end 
