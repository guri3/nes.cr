require "./types"
require "./ram"
require "./ppu_bus"
require "./interrupts"
require "./palette"

SPRITES_NUMBER = 0x100

class Ppu
  @registers : Array(Byte)
  @cycle : Int32
  @line : Int32
  @is_valid_vram_addr : Bool
  @is_lower_vram_addr : Bool
  @vram_addr : Word
  @vram : Ram
  @vram_read_buf : Byte
  @sprite_ram : Ram
  @sprite_ram_addr : Byte
  @bus : PpuBus
  @background : Array(Tile)
  @sprites : Array(SpriteWithAttribute)
  @palette : Palette
  @interrupts : Interrupts

  # @is_horizontal_scroll : Bool
  # @scroll_x : Byte
  # @scroll_y : Byte
  # @config : Config

  def initialize(@bus, @interrupts)
    @registers = Array(Byte).new(0x08, 0_u8)
    @cycle = 0
    @line = 0
    @is_valid_vram_addr = false
    @is_lower_vram_addr = false
    @vram_addr = 0x0000
    @vram = Ram.new(0x2000)
    @vram_read_buf = 0x00
    @sprite_ram = Ram.new(0x0100)
    @sprite_ram_addr = 0x0000
    @background = [] of Tile
    @sprites = [] of SpriteWithAttribute
    @palette = Palette.new
    # @is_horizontal_scroll = true
    # @scroll_x = 0
    # @scroll_y = 0
  end

  def run(cycle : Int32) : RenderingData | Nil
    @cycle += cycle
    if @line == 0
      @background.clear
    end

    if @cycle >= 341
      @cycle -= 341
      @line += 1

      # if self.has_sprite_hit
      # self.set_sprite_hit
      # end

      if @line <= 240 && @line % 8 == 0
        self.build_background
      end

      if @line == 241
        # self.set_v_blank
        # if self.has_vblank_irq_enabled
        # @interrupts.assert_nmi
        # end
      end

      if @line == 262
        # self.clear_vblank
        # self.clear_sprite_hit
        @line = 0
        # @interrupts.deassert_nmi
        return RenderingData.new(
          self.is_background_enable ? @background : nil,
          self.is_sprite_enable ? @sprites : nil,
          self.get_palette
        )
      end
    end
    nil
  end

  def read(addr : Word) : Byte
    if addr === 0x0002
      # @is_horizontal_scroll = true
      data = @registers[0x02]
      # self.clear_vblank
      data
    end
    if addr == 0x0004
      @sprite_ram.read(@sprite_ram_addr.to_u16)
    end
    if addr == 0x0007
      return self.read_vram
    end
    0_u8
  end

  def write(addr : Word, data : Byte)
    if addr == 0x0006
      self.write_vram_addr(data)
    end
    if addr == 0x0007
      self.write_vram_data(data)
    end
    @registers[addr] = data
  end

  private def read_vram : Byte
    buf = @vram_read_buf
    if @vram_addr >= 0x2000
      addr = self.calc_vram_addr
      @vram_addr += self.vram_offset
      if addr >= 0x3f00
        return @vram.read(addr)
      end
    else
      @vram_read_buf = self.read_character_ram(@vram_addr)
      @vram_addr += vram_offset
    end
    buf
  end

  private def write_vram_addr(data : Byte)
    if (@is_lower_vram_addr)
      @vram_addr += data
      @is_lower_vram_addr = false
      @is_valid_vram_addr = true
    else
      @vram_addr = data.to_u16 << 8
      @is_lower_vram_addr = true
      @is_valid_vram_addr = false
    end
  end

  private def write_vram_data(data : Byte)
    if @vram_addr >= 0x2000
      if @vram_addr >= 0x3F00 && @vram_addr < 0x4000
        @palette.write(@vram_addr - 0x3f00, data)
      else
        self.write_vram(self.calc_vram_addr, data)
      end
    else
      self.write_character_ram(@vram_addr, data)
    end
    @vram_addr += self.vram_offset
  end

  private def write_vram(addr : Word, data : Byte)
    @vram.write(addr, data)
  end

  private def write_character_ram(addr : Word, data : Byte)
    @bus.write_by_ppu(addr, data)
  end

  private def calc_vram_addr : UInt16
    @vram_addr >= 0x3000 && @vram_addr < 0x3f00 ? (@vram_addr -= 0x3000) : @vram_addr - 0x2000
  end

  private def vram_offset
    @registers[0x00] & 0x04 != 0 ? 32 : 1
  end

  private def build_background
    clamped_tile_y = self.tile_y % 30
    (0...32).each do |x|
      clamped_tile_x = (x % 32).to_u8
      name_table_id = (x / 32).to_u16 % 2
      offset_addr_by_name_table = name_table_id * 0x0400
      tile = self.build_tile(clamped_tile_x, clamped_tile_y, offset_addr_by_name_table)
      @background.push(tile)
    end
  end

  private def tile_y : Byte
    (@line / 8).to_u8
  end

  private def build_tile(tile_x : Byte, tile_y : Byte, offset : Word) : Tile
    block_id = self.get_block_id(tile_x, tile_y)
    sprite_id = self.get_sprite_id(tile_x, tile_y, offset)
    attr = self.get_attribute(tile_x, tile_y, offset)
    palette_id = attr >> block_id * 2 & 0x03
    sprite = self.build_sprite(sprite_id, self.background_table_offset)
    Tile.new(sprite, palette_id)
  end

  private def get_block_id(tile_x : Byte, tile_y : Byte) : Byte
    (tile_x % 4 / 2).to_u8 + (tile_y % 4.to_u8 / 2).to_u8 * 2
  end

  private def get_sprite_id(tile_x : Byte, tile_y : Byte, offset : Word) : Byte
    tile_number = tile_y.to_u16 * 32 + tile_x
    sprite_addr = self.mirror_down_sprite_addr(tile_number + offset)
    @vram.read(sprite_addr)
  end

  private def mirror_down_sprite_addr(addr : Word) : Word
    if addr >= 0x0400 && addr < 0x0800 || addr >= 0x0C00
      return addr -= 0x0400
    end
    addr
  end

  private def get_attribute(tile_x : Byte, tile_y : Byte, offset : Word) : Byte
    addr = (tile_x / 4).to_u16 + (tile_y / 4).to_u16 * 8 + 0x03c0 + offset
    @vram.read(self.mirror_down_sprite_addr(addr))
  end

  private def background_table_offset : Word
    @registers[0] & 0x10 == 1 ? 0x1000.to_u16 : 0x0000.to_u16
  end

  private def build_sprite(sprite_id : Byte, offset : Word) : Sprite
    sprite = (0..8).map { |_| [0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8] }
    (0...16).each do |i|
      (0...8).each do |j|
        addr = sprite_id.to_u16 * 16 + i + offset
        ram = self.read_character_ram(addr)
        if ram & 0x80 >> j != 0
          sprite[i % 8][j] += 0x01 << (i / 8).to_u8
        end
      end
    end
    sprite
  end

  private def read_character_ram(addr : Word) : Byte
    @bus.read_by_ppu(addr)
  end

  private def is_background_enable : Bool
    @registers[0x01] & 0x08 != 0
  end

  private def is_sprite_enable : Bool
    (@registers[0x01] & 0x10) != 0
  end

  private def get_palette : Array(Byte)
    @palette.read
  end

  # 以下、hello.nesの描画には未使用
  #   def build_sprites
  #     offset = (@registers[0] & 0x08) == 0x01 ? 0x1000 : 0x0000
  #     i = 0_u16
  #     while i < SPRITES_NUMBER
  #       y = @sprite_ram.read(i).to_i32
  #       # next if y < 0
  #       sprite_id = @sprite_ram.read(i + 1)
  #       attr = @sprite_ram.read(i + 2)
  #       x = @sprite_ram.read(i + 3)
  #       sprite = self.build_sprite(sprite_id, offset.to_u16)
  #       @sprites.push(SpriteWithAttribute.new(sprite, x, y.to_u8, attr, sprite_id))
  #       i += 4
  #     end
  #   end

  #   private def has_sprite_hit : Bool
  #     y = @sprite_ram.read(0x0000)
  #     y == @line && self.is_background_enable && self.is_sprite_enable
  #   end

  #   private def set_sprite_hit
  #     @registers[2] |= 0x40
  #   end

  #   private def has_vblank_irq_enabled : Bool
  #     (@registers[0] & 0x80) != 0
  #   end

  #   private def transfer_sprite(index : UInt8, data : UInt8)
  #     addr = index + @sprite_ram_addr
  #     @sprite_ram.write(addr.to_u16 % 0x100, data)
  #   end

  #   private def set_v_blank
  #     @registers[0x02] |= 0x80
  #   end

  #   private def clear_vblank
  #     @registers[0x02] &= 0x7f
  #   end

  #   private def clear_sprite_hit
  #     @registers[0x02] &= 0xbf
  #   end
end
