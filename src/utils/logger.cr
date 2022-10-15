require "../nes/cpu_register"

class Logger
  @file : File

  def initialize
    now = Time.local
    file_path = "./logs/#{now.to_s("%Y%m%d%H%M%S")}.log"
    @file = File.open(file_path, "w")
  end

  def logging(register : CpuRegister, base_name : String, mode : String, cycle : Int32)
    @file.puts "#{register.pc.to_s(16)} #{base_name} #{mode}  A:#{register.a} X:#{register.x} Y:#{register.y} SP:#{register.sp} CYC: #{cycle}"
  end
end
