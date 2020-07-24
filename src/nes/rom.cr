class Rom
  def initialize(data : Bytes)
    @rom = data
  end

  def size
    @rom.size
  end

  def read(addr : UInt16) UInt8
    @rom[addr]
  end
end
