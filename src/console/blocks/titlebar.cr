module Trollio::Console::Blocks
  class Titlebar < Hokusai::Block
    GREEN = [38, 200, 75]
    YELLOW = [253, 189, 61]
    RED = [255, 92, 87]
    DEFAULT = [133, 133, 133]
    DRAG = [46,49,63]

    @@template = <<-EOF
    [template]
      hblock {
        :background="get_background"
        :outline="outline"
        :outline_color="outline_color"
        :outline_bottom="outline_bottom"
        :outline_top="outline_top"
        :outline_left="outline_left"
        :outline_right="outline_right"
        @click="start_move"
        :rounding="rounding"
        @mousemove="move"
        @hover="set_hover"
        @mouseout="clear_hover"
      }
        vblock { width="4" }
          empty
        vblock { width="60" }
          hblock 
            circle { @click="close" @hover="hover_red" @mouseout="blur_red" :radius="radius" :color="red" }
            circle { @click="minimize" @hover="hover_yellow" @mouseout="blur_yellow" :radius="radius" :color="yellow" }
            circle { @click="maximize" @hover="hover_green" @mouseout="blur_green" :radius="radius" :color="green" }
        vblock
          hblock
            slot
    EOF

    computed(outline, Float32, 0.0f32, true)
    computed(outline_color, Array(Int32), [0,0,0,0], true)
    computed(outline_top, Bool, false, true)
    computed(outline_bottom, Bool, false, true)
    computed(outline_left, Bool, false, true)
    computed(outline_right, Bool, false, true)

    computed(unhovered_color, Array(Int32), DEFAULT)
    computed(rounding, Float32?, nil, true)
    computed(radius, Float32, 6.0f32, true)
    computed(background, Array(Int32)?, nil, true)
    uses(circle: Hokusai::Blocks::Circle, vblock: Hokusai::Blocks::Vblock, hblock: Hokusai::Blocks::Hblock, empty: Hokusai::Blocks::Empty)

    @[Hokusai::Method]
    def get_background
      @moving ? DRAG : background
    end

    @[Hokusai::Target]
    def start_move(*, event : Hokusai::ClickEvent)
      @moving = true
      @last_mouse = event
      nil
    end

    @[Hokusai::Target]
    def move(*, event : Hokusai::MouseMoveEvent)
      if @moving && event.left.down
        if lmouse = @last_mouse
          # if (event.delta.x > 0 || event.delta.y > 0 || event.delta.x < 0 || event.delta.y < 0)
            Hokusai.set_window_position(lmouse)
          # end
          nil
        end
      else
        @moving = false
        nil
      end
    end

    @[Hokusai::Target]
    def set_hover(*, event : Hokusai::HoverEvent)
      @hover = true
    end

    @[Hokusai::Target]
    def clear_hover(*, event : Hokusai::MouseOutEvent)
      @hover = false
    end

    @[Hokusai::Target]
    def close
      @moving = false
      Hokusai.close_window
    end

    @[Hokusai::Target]
    def minimize
      @moving = false
      Hokusai.minimize_window
    end

    @[Hokusai::Target]
    def maximize
      @moving = false
      Hokusai.maximize_window
    end

    @[Hokusai::Target]
    def blur_red(*, event : Hokusai::MouseOutEvent)
      @hovered_red = false
    end

    @[Hokusai::Target]
    def blur_yellow(*, event : Hokusai::MouseOutEvent)
      @hovered_yellow = false
    end

    @[Hokusai::Target]
    def blur_green(*, event : Hokusai::MouseOutEvent)
      @hovered_green = false
    end

    @[Hokusai::Target]
    def hover_red(*, event : Hokusai::HoverEvent)
      @hovered_red = true
    end

    @[Hokusai::Target]
    def hover_yellow(*, event : Hokusai::HoverEvent)
      @hovered_yellow = true
    end

    @[Hokusai::Target]
    def hover_green(*, event : Hokusai::HoverEvent)
      @hovered_green = true
    end

    @[Hokusai::Method]
    def red
      @hovered_red ? RED : unhovered_color
    end

    @[Hokusai::Method]
    def yellow
      @hovered_yellow ? YELLOW : unhovered_color
    end

    @[Hokusai::Method]
    def green
      @hovered_green ? GREEN : unhovered_color
    end

    @last_mouse : Hokusai::ClickEvent?

    def initialize(**args)
      super(**args)
      @hovered_red = false
      @hovered_yellow = false
      @hovered_green = false
      @moving = false
      @hover = false
      @last_mouse = nil
    end
  end
end
