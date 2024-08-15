require "../sessions/command"
require "./ansi"

module Trollio::Console::Blocks
  class Command < Hokusai::Block
    @@template = <<-EOF
    [template]
      hblock {
        outline="1"
        outline_bottom="true"
        :outline_color="outline_color"
        :background="background_computed"
      }
        [if="error"]
          rect { color="229,43,77" width="8" }
            empty
        vblock
          [if="has_input_text"]
            text {
              height="20"
              :content="input"
              :color="text_color"
              :selection_color="computed_selection_color"
              size="15"
              padding="10,20,10,20"
            }
          ansi {
            :content="command_output"
            :padding="text_padding"
            :selection_color="computed_selection_color"
            :size="size"
            @height_updated="command_update_height"
            @clear="clear"
          }
    EOF

    uses(
      text: Hokusai::Blocks::Text,
      hblock: Hokusai::Blocks::Hblock,
      rect: Hokusai::Blocks::Rect,
      empty: Hokusai::Blocks::Vblock,
      vblock: Hokusai::Blocks::Vblock,
      ansi: Blocks::ANSI,
    )

    inject(:theme, :theme, Theme)
    computed!(command, Sessions::Command)
    computed(use_ansi, Bool, true, true)
    computed(size, Int32, 18, true)
    computed(text_padding, Array(Float32), [15f32, 20f32, 15f32, 20f32], true)
    computed(outline_color, Array(Int32), theme.outline_color, true)
    computed(selection_color, Array(Int32), theme.selection_color, true)
    computed(text_color, Array(Int32), theme.prompt_color, true)
    computed(background_color, Array(Int32), theme.background_color, true)

    property cursor : Int32 = -1

    @[Hokusai::Target]
    def clear
      emit("clear")
    end

    @[Hokusai::Target]
    def command_update_height(*, value : Float32)
      value += 40 if has_input_text
      command.height = value - 1
    end

    @[Hokusai::Method]
    def computed_selection_color
      error ? [94,33,45] : selection_color 
    end
    
    @[Hokusai::Method]
    def command_output
      command.output || "(no output)"
    end

    @[Hokusai::Target]
    def cursor_set_offset(*, value : Int32)
      self.cursor = value
    end

    @[Hokusai::Method]
    def has_input_text
      command.command || false
    end

    @[Hokusai::Method]
    def input
      command.command
    end

    @[Hokusai::Method]
    def error
      command.error || false
    end

    @[Hokusai::Method]
    def cursor_offset
      cursor
    end

    @[Hokusai::Method]
    def background_computed
      error ? "81,53,63" : background_color
    end
  end
end
