require "hokusai/ui/src/hokusai"
require "hokusai/ui/src/hokusai/backends/raylib"
require "hokusai/ui/src/hokusai/blocks/*"


class PanelTest < Hokusai::Block
  @@template = <<-EOF
  [template]
    vblock
      hblock
        panel
          rect { color="244,0,0" height="900"}
            text { content="bar" size="20" }
      panel
        rect {color="0,244,244", height="900"}
          text { content="foo" size="30" }
  EOF

  uses(
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    panel: Hokusai::Blocks::Panel,
    rect: Hokusai::Blocks::Rect,
    empty: Hokusai::Blocks::Empty,
    text: Hokusai::Blocks::Text
  )

  def update
    super
  end
end

Hokusai::Backends::RaylibBackend.run(PanelTest) do |config|
  config.width = 600
  config.height = 600
  config.title = "Trollio Console"
  config.background = Raylib::BLANK
  config.config_flags = Raylib::ConfigFlags::WindowBorderlessWindowedMode
  config.window_state_flags = ::Raylib::ConfigFlags::WindowResizable
end