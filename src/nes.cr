require "./nes/emu"
require "crsfml"

window = SF::RenderWindow.new(SF::VideoMode.new(256, 240), "nes.cr")
window.framerate_limit = 60

points = [
  SF::Vertex.new(SF.vector2f(10, 10), SF::Color::Red),
  SF::Vertex.new(SF.vector2f(20, 20), SF::Color::Red),
]

while window.open?
  while event = window.poll_event
    if event.is_a? SF::Event::Closed
      window.close
    end
  end
  window.draw(points, SF::Points)
  window.display
end

# nes_file = File.new("roms/hello.nes")
# buf = Bytes.new(nes_file.size)
# nes_file.read(buf)
# emu = Emu.new(buf)
# emu.run
