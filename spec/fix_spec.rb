RSpec.configure do |config|
  config.mock_framework = :mocha
end
require_relative '../lib/fix.rb'
SOH="\1"
FIXMSG1="8=FIXT.1.1\x019=121\x0135=A\x0149=YOURUSER018437\x0156=TR MATCHING\x0134=3884\x01142=YOURTARGET1234567890\x0152=20131118-14:48:16\x0198=0\x01108=4\x01789=3817\x011137=9\x011407=100\x0110=143\x01"

FIXMSG1_EXPANDED={
  8 => "FIXT.1.1",
  9 => "121",
  35 => "A",
  49 => "YOURUSER018437",
  56 => "TR MATCHING",
  34 => "3884",
  142 => "YOURTARGET1234567890",
  52 => "20131118-14:48:16",
  98 => "0",
  108 => "4",
  789 => "3817",
  1137 => "9",
  1407 => "100",
  10 => "143",
}

describe Fix::FixMessage, "#checksum" do
  it "calculates a correct checksum" do
    m=Fix::FixMessage.from_fix(FIXMSG1)
    m.checksum(m._fix_wo_checksum).should eq("143")
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
describe Fix::FixMessage, "#calc_length" do
  it "calculates length correctly" do
    m=Fix::FixMessage.from_fix(FIXMSG1)
    m.update_length
    #puts m
    m.calc_length.to_s.should  eq("128")

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
  it "allows dupe tags", "#to_fix" do
    m=Fix::FixMessage.from_fix(FIXMSG1)
    dupes=["YOURUSER018437","YOURUSER018437"]
    m.set_tag 49, dupes
    msg=m.to_fix
    # puts m.to_s
    matches=msg.scan (/49=(\w+)/)
    matches.count.should eq 2
    (matches.map {|v| v[0].to_s}).should eq dupes

  end
  it "puts tags in correct order" do
    m=Fix::FixMessage.from_fix(FIXMSG1)
    m.prepare_fix!
    # puts m.to_s
    pairs=(m.to_fix).split SOH
    # Tag 8 comes 1st
    tag,value=pairs[0].split "="
    tag.should eq("8")
    # Tag 9 - BodyLength comes 2nd
    tag,value=pairs[1].split "="
    tag.should eq("9")
    # Tag 35 is third
    tag,value=pairs[2].split "="
    tag.should eq("35")
    # Tag 10 - checksum comes last
    tag,value=pairs[-1].split "="
    tag.should eq("10")

  end
end