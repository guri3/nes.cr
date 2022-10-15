require "../nes/cpu_register"

class Logger
  @file : File

  def initialize
    now = Time.local
    file_path = "./logs/#{now.to_s("%Y%m%d%H%M%S")}.log"
    @file = File.open(file_path, "w")
  end

  def logging(register : CpuRegister, base_name : String, mode : String, cycle : Int32)
    log_row = sprintf("%04X %s %s A:%02X X:%02X Y:%02X SP:%02X CYC:%d", register.pc, base_name, mode, register.a, register.x, register.y, register.sp - 0x0100, cycle)
    @file.puts log_row
  end
end
