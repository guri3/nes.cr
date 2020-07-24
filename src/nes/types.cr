alias Byte = UInt8
alias Word = UInt16

alias PaletteRam = Array(UInt8)
alias Sprite = Array(Array(UInt8))

class SpriteWithAttribute
  getter sprite : Sprite
  getter x : Byte
  getter y : Byte
  getter attr : Byte
  getter sprite_id : UInt8

  def initialize(@sprite, @x, @y, @attr, @sprite_id)
  end
end

class Tile
  getter sprite : Sprite
  getter palette_id : Byte

  def initialize(@sprite, @palette_id)
  end
end

class RenderingData
  getter background : Array(Tile) | Nil
  getter sprites : Array(SpriteWithAttribute) | Nil
  getter palette : PaletteRam

  def initialize(@background, @sprites, @palette)
  end
end
