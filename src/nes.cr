require "./nes/emu"
require "crsfml"
require "imgui"
require "imgui-sfml"

window = SF::RenderWindow.new(SF::VideoMode.new(256, 240), "nes.cr")
window.framerate_limit = 60
ImGui::SFML.init(window)

io = ImGui.get_io
io.config_flags |= ImGui::ImGuiConfigFlags::NavEnableKeyboard
io.config_flags |= ImGui::ImGuiConfigFlags::NavEnableGamepad

shape = SF::CircleShape.new(100)
shape.fill_color = SF::Color::Green

delta_clock = SF::Clock.new
while window.open?
  while (event = window.poll_event)
    ImGui::SFML.process_event(window, event)

    if event.is_a? SF::Event::Closed
      window.close
    end
  end

  ImGui::SFML.update(window, delta_clock.restart)

  window.clear
  window.draw(shape)
  ImGui::SFML.render(window)
  window.display
end

ImGui::SFML.shutdown

# nes_file = File.new("roms/hello.nes")
# buf = Bytes.new(nes_file.size)
# nes_file.read(buf)
# emu = Emu.new(buf)
# emu.run
