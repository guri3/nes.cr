require "../nes/cpu_register"

class Logger
  FILE_PATH        = "./logs/nestest.log"
  FILE_PATH_DETAIL = "./logs/nestest_detail.log"

  property register : CpuRegister = CpuRegister.new
  property pc : Int32 = 0
  property cycle : Int32 = 7
  property opecode : UInt8 = 0x00
  property base_name : String = ""
  property mode : String = ""
  property opeland : UInt16 = 0x0000

  def initialize
    # now = Time.local
    # file_path = "./logs/#{now.to_s("%Y%m%d%H%M%S")}.log"
    File.delete?(FILE_PATH)
    File.delete?(FILE_PATH_DETAIL)
  end

  def logging
    log_row = sprintf("A:%02X X:%02X Y:%02X P:%02X SP:%02X", @register.a, @register.x, @register.y, @register.status_to_u8, @register.sp - 0x0100)
    log_row_detail = sprintf("%04X  %02X %02X %02X  %s  A:%02X X:%02X Y:%02X P:%02X SP:%02X CYC:%d", pc, @opecode, opeland_lower, opeland_upper, base_name, @register.a, @register.x, @register.y, @register.status_to_u8, @register.sp - 0x0100, @cycle)
    # puts log_row
    File.open(FILE_PATH, "a") do |file|
      file.puts log_row
    end
    File.open(FILE_PATH_DETAIL, "a") do |file|
      file.puts log_row_detail
    end
  end

  def opeland_upper : UInt8
    (@opeland >> 8).to_u8
  end

  def opeland_lower : UInt8
    (@opeland & 0x00FF).to_u8
  end
end
