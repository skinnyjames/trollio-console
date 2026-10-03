require "hokusai/ui/src/hokusai"
require "hokusai/ui/src/hokusai/backends/raylib"
require "hokusai/ui/src/hokusai/blocks/*"
require "./lib/vtparse"
require "./console/**"

class Trollio::Error < Exception; end

module Trollio::Console::Blocks
  class Main < Hokusai::Block
    @@template = <<-EOF
    [template]
      vblock#outline {
        rounding="0.025"
        :background="background"
        outline="2.5"
        outline_color="36,38,48"
      }
        vblock#main { 
          rounding="0.025"
          outline="1.5"
          outline_color="123,132,181"
        }
          titlebar {
            height="28" 
            radius="6.0"
            outline="1.5"
            :background="background"
            :outline_color="outline_color"
            outline_bottom="true"
          }
            empty
            empty
            hblock#icons { width="57" }
              vblock
                empty { height="8" }
                svg { :src="search_icon" size="25" width="25" height="25" }
              vblock
                empty { height="8" }
                svg { :src="gear_icon" size="25" width="25" height="25" }
          selectable {
            cursor_color="255,92,87"
          }         
            multiplex {
              @bell="session_play_bell"
            }
    EOF

    uses(
      multiplex: Multiplex,
      session: Sessions::Traditional,
      titlebar: Titlebar,
      selectable: Hokusai::Blocks::Selectable,
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock,
      empty: Hokusai::Blocks::Empty,
      svg: Hokusai::Blocks::SVG
    )

    computed(background, Array(Int32), theme.background_color, true)
    computed(outline_color, Array(Int32), theme.outline_color, true)

    getter theme : Theme
    getter multiplex_sessions = [] of String

    @[Hokusai::Target]
    def session_play_bell
      STDOUT.print "\a"
    end

    @[Hokusai::Method(provide: "theme")]
    def console_theme
      theme
    end

    @[Hokusai::Method(provide: "sessions")]
    def sessions
      multiplex_sessions
    end

    @[Hokusai::Method]
    def gear_icon
      "#{__DIR__}/console/icons/gear.svg"
    end

    @[Hokusai::Method]
    def search_icon
      "#{__DIR__}/console/icons/search.svg"
    end

    def on_mounted
      super
    end

    def initialize(**args)
      super(**args)

      if filename = ENV["TROLLIO_CONSOLE_THEME"]?
        @theme = Theme.from_file(filename)
      else
        @theme = Theme.default
      end

      puts theme.inspect
    end
  end

  Hokusai::Backends::RaylibBackend.run(Main) do |config|
    config.after_load do
      monaco = Hokusai::Backends::RaylibBackend::Font.from_ext("#{__DIR__}/Monaco.ttf", 28)
      monaco_bold = Hokusai::Backends::RaylibBackend::Font.from_ext("#{__DIR__}/MonacoB2.ttf", 28)
  
      Hokusai.fonts.register "monaco", monaco
      Hokusai.fonts.register "monaco_bold", monaco_bold
      Hokusai.fonts.activate "monaco"
    end
  
    config.width = 600
    config.height = 600
    config.title = "Trollio Console"
    config.background = Raylib::BLANK
    config.config_flags = Raylib::ConfigFlags::WindowBorderlessWindowedMode | Raylib::ConfigFlags::WindowTransparent | Raylib::ConfigFlags::WindowUndecorated
    config.window_state_flags = ::Raylib::ConfigFlags::WindowResizable
  end
end

