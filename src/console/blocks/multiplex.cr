require "./sessions/traditional"

module Trollio::Console
  class Multiplex < Hokusai::Block
    @@template = <<-EOF
    [template]
      vblock
        hblock
          session { 
            @new_session="session_create" 
          }
          [for="item in horizontal_sessions"]
            multiplex { vertical="false" }
        [for="item in vertical_sessions"]
          multiplex { vertical="true" }
    EOF

    uses(
      session: Sessions::Traditional,
      multiplex: Multiplex,
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock
    )

    inject(:theme, :theme, Theme)
    computed(outline_color, Array(Int32), theme.outline_color, true)
    computed(root, Bool, true)
    computed(vertical, Bool, true)

    getter multi_horizontal_sessions = [] of Bool
    getter multi_vertical_sessions = [] of Bool


    getter random_color : Array(Int32) = [[255,0,0], [0,255,255], [0,0,255], [0,255,0]].sample

    @[Hokusai::Target]
    def session_create(*, vertical : Bool)
      if vertical
        multi_vertical_sessions << true
      else
        multi_horizontal_sessions << true
      end
    end

    @[Hokusai::Method]
    def horizontal_sessions
      multi_horizontal_sessions
    end

    @[Hokusai::Method]
    def vertical_sessions
      multi_vertical_sessions
    end

    @[Hokusai::Method]
    def multiplex(*, index : Int32, item : Hokusai::Value)
      item.get(Bool)
    end

    @[Hokusai::Target]
    def session_focus
      children[1].node.meta.focus

      children[0]?.try do |child|
        child.node.meta.blur
      end
    end

    @[Hokusai::Target]
    def session_bell
      emit("bell")
    end

    def on_mounted
      node.meta.focus

      super
    end

    def update
      # puts dump
      super
    end

    @[Hokusai::Method]
    def outline_position
      vertical ? [true, false, false, false] : [false, false, false, true]
    end

    def render(canvas : Hokusai::Canvas, &)
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.outline(1)
          command.outline_color(outline_color)
          command.outline_position(outline_position)
        end
      end

      yield(canvas)
    end
  end
end
