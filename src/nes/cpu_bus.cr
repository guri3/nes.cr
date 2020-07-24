require "./types"
require "./ram"
require "./rom"
require "./ppu"

# require "./dma"
# require "./keypad"
# require "./apu"

class CpuBus
  def initialize(@ram : Ram, @program_rom : Rom, @ppu : Ppu)
    # @dma = dma
    # @keypad = keypad
    # @apu = apu
  end

  def read_by_cpu(addr : Word) : Byte
    if addr < 0x0800 # WRAM
      @ram.read(addr)
    elsif addr < 0x2000 # WRAM mirror
      @ram.read(addr - 0x0800)
    elsif addr < 0x4000 # PPU
      @ppu.read((addr - 0x2000) % 8)
    elsif addr == 0x4016
      # return +this.keypad.read TODO
      0_u8
    elsif addr >= 0xC000 # PRG-ROM
      if @program_rom.size <= 0x4000
        return @program_rom.read(addr - 0xC000)
      end
      @program_rom.read(addr - 0x8000)
    elsif addr >= 0x8000 # PRG-ROM
      @program_rom.read(addr - 0x8000)
    else
      0_u8
    end
  end

  def write_by_cpu(addr : Word, data : Byte)
    if addr < 0x0800 # RAM
      @ram.write(addr, data)
    elsif addr < 0x2000 # RAM mirror
      @ram.write(addr - 0x0800, data)
    elsif addr < 0x2008 # PPU
      @ppu.write(addr - 0x2000, data)
    elsif addr >= 0x4000 && addr < 0x4020
      if addr == 0x4014
        # @dma.write(data) TODO
      elsif addr == 0x4016
        # @keypad.write(data) TODO
      else
        # @apu.write(addr - 0x4000, data) TODO
      end
    end
  end
end
