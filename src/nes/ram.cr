require "./types"

class Ram
  getter ram : Array(Byte)

  def initialize(size : Int32)
    @ram = Array.new(size, 0_u8)
  end

  def reset
    @ram.map! 0_u8
  end

  def read(addr : Word) : Byte
    @ram[addr]
  end

  def write(addr : Word, data : Byte)
    @ram[addr] = data
  end
end
