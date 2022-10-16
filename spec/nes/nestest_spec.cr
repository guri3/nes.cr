require "spec"
require "../../src/nes/emu"

describe "Nestest" do
  nes_file = File.new("roms/nestest.nes")
  buf = Bytes.new(nes_file.size)
  nes_file.read(buf)
  emu = Emu.new(buf)
  begin
    emu.run
  rescue exception
    # テスト実行のため握りつぶす
  end

  it "CPUの状態がnestest.logと一致すること" do
    puts
    File.read_lines("logs/nestest.log").each_with_index(1) do |line, i|
      File.read_lines("spec/data/nestest.log").each_with_index(1) do |expected_line, j|
        if i == j
          puts "line: #{i}"
          line.should eq(expected_line)
        end
      end
    end
  end
end
