require "./types"
require "./ram"

class PpuBus
  @character_ram : Ram

  def initialize(character_ram : Ram)
    @character_ram = character_ram
  end

  def read_by_ppu(addr : Word) : Byte
    @character_ram.read(addr)
  end

  def write_by_ppu(addr : Word, data : Byte)
    @character_ram.write(addr, data)
  end
end
