require "./types"

class Palette
  @ram : PaletteRam

  def initialize
    @ram = PaletteRam.new(0x20, 0_u8)
  end

  def read : PaletteRam
    @ram.map_with_index do |v, i|
      next @ram[i - 0x10] if self.is_sprite_mirror?(i.to_u8)
      next @ram[0x00] if self.is_background_mirror?(i.to_u8)
      v
    end
  end

  def write(addr : Word, data : Byte)
    @ram[self.get_palette_addr(addr)] = data
  end

  private def is_background_mirror?(addr : UInt8) : Bool
    addr == 0x04 || addr == 0x08 || addr == 0x0c
  end

  private def get_palette_addr(addr : Word) : Byte
    mirror_downed = (addr & 0xFF).to_u8 % 0x20
    # 0x3f10, 0x3f14, 0x3f18, 0x3f1c は 0x3f00, 0x3f04, 0x3f08, 0x3f0c のミラー
    self.is_sprite_mirror?(mirror_downed) ? mirror_downed - 0x10 : mirror_downed
  end

  private def is_sprite_mirror?(addr : Byte) : Bool
    addr == 0x10 || addr == 0x14 || addr == 0x18 || addr == 0x1c
  end
end
