require "./nes/emu"
require "crsfml"

window = SF::RenderWindow.new(SF::VideoMode.new(256, 240), "nes.cr")
window.framerate_limit = 60

vertices = [
  SF::Vertex.new(SF.vector2f(0, 0), SF::Color::Red, SF.vector2f(0, 0)),
  SF::Vertex.new(SF.vector2f(0, 100), SF::Color::Red, SF.vector2f(0, 10)),
  SF::Vertex.new(SF.vector2f(100, 100), SF::Color::Red, SF.vector2f(10, 10)),
  SF::Vertex.new(SF.vector2f(100, 0), SF::Color::Red, SF.vector2f(10, 0)),
]

while window.open?
  while event = window.poll_event
    if event.is_a? SF::Event::Closed
      window.close
    end
  end
  window.draw(vertices, SF::Quads)
  window.display
end

# nes_file = File.new("roms/hello.nes")
# buf = Bytes.new(nes_file.size)
# nes_file.read(buf)
# emu = Emu.new(buf)
# emu.run
