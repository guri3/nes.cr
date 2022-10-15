require "./types"
require "./cpu_bus"
require "./cpu_const"
require "./cpu_register"
require "../utils/logger"

class Cpu
  @bus : CpuBus
  @register : CpuRegister
  @has_branched : Bool
  @logger : Logger

  def initialize(bus : CpuBus)
    @bus = bus
    @register = CpuRegister.new
    @has_branched = false
    @logger = Logger.new
  end

  def reset
    # @register.pc = self.read(0xFFFC).to_u16 || 0x8000_u16
    # TODO: レジスタの初期化
    @register.pc = 0xC000
  end

  def run(original_cycle : Int32) : Int32
    @logger.register = @register
    @logger.pc = @register.pc
    opecode = self.fetch(@register.pc)
    @logger.opecode = opecode
    base_name, mode, cycle = OPELAND_DICT[opecode]
    @logger.base_name = base_name.as(String)
    @logger.mode = mode.as(String)
    opeland, additional_cycle = self.get_opeland_with_additional_cycle(mode.as(String))
    @logger.opeland = opeland.as(UInt16)
    @logger.logging
    @logger.cycle += cycle.as(Int32)
    self.exec(base_name.as(String), opeland.as(UInt16), mode.as(String))
    cycle.as(Int32) + additional_cycle + (@has_branched ? 1 : 0)
  end

  private def fetch(addr : Word) : Byte
    @register.pc += 1
    self.read(addr)
  end

  private def get_opeland_with_additional_cycle(addressing : String) : Array(Word | Int32)
    case addressing
    when "accumulator"
      [0_u16, 0]
    when "implied"
      [0_u16, 0]
    when "immediate"
      [self.fetch(@register.pc).to_u16, 0]
    when "relative"
      base_addr = self.fetch(@register.pc).to_u16
      addr = base_addr < 0x0080 ? base_addr + @register.pc : base_addr + @register.pc - 0x0100
      additional_cycle = addr & 0x00ff != @register.pc & 0xff00 ? 1 : 0
      [addr, additional_cycle]
    when "zeroPage"
      [self.fetch(@register.pc).to_u16, 0]
    when "zeroPageX"
      addr = self.fetch(@register.pc).to_u16
      [addr + @register.x, 0]
    when "zeroPageY"
      addr = self.fetch(@register.pc).to_u16
      [addr + @register.y, 0]
    when "absolute"
      [self.fetch_word(@register.pc), 0]
    when "absoluteX"
      addr = self.fetch_word(@register.pc)
      additional_cycle = addr & 0xff00 != addr + @register.y & 0xff00 ? 1 : 0
      [addr + @register.x, additional_cycle]
    when "absoluteY"
      addr = self.fetch_word(@register.pc)
      additional_cycle = addr & 0xff00 != addr + @register.y & 0xff00 ? 1 : 0
      [addr + @register.y, additional_cycle]
    when "preIndexedIndirect"
      base_addr = self.fetch(@register.pc).to_u16 + @register.x & 0x00ff
      addr = self.read(base_addr).to_u16 + (self.read(base_addr + 1).to_u16 << 8)
      additional_cycle = addr & 0xff00 != base_addr & 0xff00 ? 1 : 0
      [addr, additional_cycle]
    when "postIndexedIndirect"
      addr_or_data = self.fetch(@register.pc).to_u16
      base_addr = self.read(addr_or_data).to_u16 + (self.read(addr_or_data + 1) << 8)
      [base_addr + @register.y, 0]
    when "indirectAbsolute"
      addr_or_data = self.fetch_word(@register.pc).to_u16
      addr = self.read(
        addr_or_data).to_u16 + (self.read(addr_or_data & 0xff00 | ((addr_or_data & 0x00ff) + 1) & 0xFF) << 8
        )
      [addr, 0]
    else
      [0_u16, 0]
    end
  end

  private def exec(base_name : String, opeland : UInt16, mode : String)
    case base_name
    when "LDA"
      @register.a = mode === "immediate" ? opeland.to_u8 : self.read(opeland)
      @register.p["negative"] = @register.a & 0x80 != 0
      @register.p["zero"] = @register.a == 0
    when "LDX"
      @register.x = mode == "immediate" ? opeland.to_u8 : self.read(opeland)
      @register.p["negative"] = @register.x & 0x80 != 0
      @register.p["zero"] = @register.x == 0
    when "LDY"
      @register.y = mode === "immediate" ? opeland.to_u8 : self.read(opeland)
      @register.p["negative"] = @register.x & 0x80 != 0
      @register.p["zero"] = @register.x == 0
    when "STA"
      self.write(opeland, @register.a)
    when "TXS"
      @register.sp = @register.x.to_u16 + 0x0100
    when "TYA"
      @register.a = @register.y
      @register.p["negative"] = @register.a & 0x80 != 0
      @register.p["zero"] = @register.a == 0
    when "AND"
      data = mode == "immediate" ? opeland : self.read(opeland)
      operated = data & @register.a
      @register.p["negative"] = operated & 0x80 != 0
      @register.p["zero"] = operated == 0
      @register.a = operated.to_u8 & 0xff
    when "DEY"
      @register.y = @register.y - 0x01
      @register.p["negative"] = @register.y & 0x80 != 0
      @register.p["zero"] = @register.y == 0
    when "INX"
      @register.x = @register.x + 0x01
      @register.p["negative"] = @register.x & 0x80 != 0
      @register.p["zero"] = @register.x == 0
    when "INY"
      @register.y = @register.y + 0x01
      @register.p["negative"] = @register.y & 0x80 != 0
      @register.p["zero"] = @register.y == 0
    when "JMP"
      @register.pc = opeland
    when "JSR"
      pc = @register.pc - 1
      push (pc >> 8 & 0xFF).to_u8
      push (pc & 0xFF).to_u8
      @register.pc = opeland
    when "BNE"
      self.branch(opeland) if !@register.p["zero"]
    when "SEI"
      @register.p["interrupt"] = true
    when "BRK"
      interrupt = @register.p["interrupt"]
      @register.pc += 0x0001
      self.push((@register.pc >> 8 & 0x00ff).to_u8)
      self.push((@register.pc & 0x00ff).to_u8)
      @register.p["break"] = true
      self.push_status
      @register.p["interrupt"] = true
      if !interrupt
        @register.pc = self.read_word(0xfffe)
      end
      @register.pc -= 0x0001
    when "NOP"
    end
  end

  private def read(addr : Word) : Byte
    @bus.read_by_cpu(addr)
  end

  private def read_word(addr : Word) : Word
    @bus.read_by_cpu(addr).to_u16 | @bus.read_by_cpu(addr + 1).to_u16 << 8
  end

  private def write(addr : Word, data : Byte)
    @bus.write_by_cpu(addr, data)
  end

  private def fetch_word(addr : Word) : Word
    @register.pc += 2
    self.read_word(addr)
  end

  private def push(data : UInt8)
    self.write((0x0100_u16 | (@register.sp & 0xff)), data)
    @register.sp = @register.sp - 1
  end

  private def push_status
    status = 0_u8
    status += 1 << 7 if @register.p["negative"]
    status += 1 << 6 if @register.p["overflow"]
    status += 1 << 5 if @register.p["reserved"]
    status += 1 << 4 if @register.p["break"]
    status += 1 << 3 if @register.p["decimal"]
    status += 1 << 2 if @register.p["interrupt"]
    status += 1 << 1 if @register.p["zero"]
    status += 1 if @register.p["carry"]
    self.push(status)
  end

  private def branch(addr : Word)
    @register.pc = addr
    @has_branched = true
  end
end
