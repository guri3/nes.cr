require "./cpu"
require "./ppu"
require "./rom"
require "./ram"
require "./cpu_bus"
require "./ppu_bus"
require "./renderer"
require "./interrupts"

class Emu
  @cpu : Cpu
  @ppu : Ppu
  @program_rom : Rom
  @ram : Ram
  @character_mem : Ram
  @cpu_bus : CpuBus
  @ppu_bus : PpuBus
  @renderer : Renderer

  def initialize(nes : Bytes)
    program_rom, character_rom = parse(nes)
    @ram = Ram.new(0x2000)
    @character_mem = Ram.new(character_rom.size)
    character_rom.each_with_index do |_, i|
      @character_mem.write(i.to_u16, character_rom[i])
    end
    @program_rom = Rom.new(program_rom)
    @ppu_bus = PpuBus.new(@character_mem)
    @interrupts = Interrupts.new
    @ppu = Ppu.new(@ppu_bus, @interrupts)
    @cpu_bus = CpuBus.new(@ram, @program_rom, @ppu)
    @cpu = Cpu.new(@cpu_bus)
    @renderer = Renderer.new
    @cpu.reset
  end

  def run
    loop do
      cycle = 0
      cycle += @cpu.run
      rendering_data = @ppu.run(cycle * 3)
      if rendering_data
        @renderer.render(rendering_data)
        break # only hello.rom
      end
    end
  end
end

def parse(nes_buf : Bytes) : Array(Bytes)
  character_rom_pages = nes_buf[5]
  character_rom_start = 0x0010 + nes_buf[4].to_u16 * 0x4000
  character_rom_end = character_rom_start + character_rom_pages.to_u16 * 0x2000
  program_rom = nes_buf[0x0010..(character_rom_start - 1)]
  character_rom = nes_buf[character_rom_start..(character_rom_end - 1)]
  [program_rom, character_rom]
end
