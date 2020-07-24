require "./nes/emu"

nes_file = File.new("roms/hello.nes")
buf = Bytes.new(nes_file.size)
nes_file.read(buf)
emu = Emu.new(buf)
emu.run
