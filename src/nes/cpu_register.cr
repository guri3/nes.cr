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
      "break"     => true,
      "decimal"   => false,
      "interrupt" => true,
      "zero"      => false,
      "carry"     => false,
    }
    @sp = 0x01FD
    @pc = 0x0000
  end
end
