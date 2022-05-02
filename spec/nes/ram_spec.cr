require "spec"
require "../../src/nes/ram"

describe Ram do
  ram = Ram.new(0x2000)

  describe "read" do

    it "値が取得できること" do
      ram.read(0).should eq(0)
    end
  end
end
