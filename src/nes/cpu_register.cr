class CpuRegister
  property a : UInt8
  property x : UInt8
  property y : UInt8
  property p : Hash(String, Bool)
  property sp : UInt16
  property pc : UInt16

  def initialize
    @a = 0x00
    @x = 0x00
    @y = 0x00
    @p = {
      "negative"  => false,
      "overflow"  => false,
      "reserved"  => true,
      "break"     => false,
      "decimal"   => false,
      "interrupt" => true,
      "zero"      => false,
      "carry"     => false,
    }
    @sp = 0x01FD
    @pc = 0x0000
  end

  def status_to_u8
    status = 0x00_u8
    status += 1 << 7 if @p["negative"]
    status += 1 << 6 if @p["overflow"]
    status += 1 << 5 if @p["reserved"]
    status += 1 << 4 if @p["break"]
    status += 1 << 3 if @p["decimal"]
    status += 1 << 2 if @p["interrupt"]
    status += 1 << 1 if @p["zero"]
    status += 1 if @p["carry"]
    status
  end

  def set_status_from_u8(status : UInt8)
    @p["negative"] = status & 0x80 != 0
    @p["overflow"] = status & 0x40 != 0
    @p["reserved"] = status & 0x20 != 0
    @p["break"] = status & 0x10 != 0
    @p["decimal"] = status & 0x08 != 0
    @p["interrupt"] = status & 0x04 != 0
    @p["zero"] = status & 0x02 != 0
    @p["carry"] = status & 0x01 != 0
  end
end
