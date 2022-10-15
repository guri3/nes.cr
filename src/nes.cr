require "./nes/emu"
require "crsfml"

nes_file = File.new("roms/nestest.nes")
buf = Bytes.new(nes_file.size)
nes_file.read(buf)
emu = Emu.new(buf)
emu.run
