require "./style"

module Trollio::Console
  class ANSI::ColorOffsets
    private property offsets = {} of Range(Int32, Int32) => {Style, Color}

    def split(start, size) : Array({Range(Int32, Int32), Style, Color})
      styles = [] of {Range(Int32, Int32), Style, Color}
      collecting = false

      offsets.each do |range, tuple|
        query = (start..start + size)

        if query.includes?(range.begin)
          if query.includes?(range.end)
            styles << {range, tuple[0], tuple[1]}

            start = range.end
            size = query.end - range.end
          else
            styles << {(start...start + size), tuple[0], tuple[1]}
            break
          end
        end
      end

      return styles
    end

    def []?(index)
      offsets.find do |key, value|
        return value if key.includes?(index)
      end
    end

    def []=(range, value)
      offsets[range] = value
    end

    def to_s(io)
      offsets.to_s(io)
    end

    def each(&)
      offsets.each do |k, v|
        yield(k, v)
      end
    end

    def empty?
      offsets.empty?
    end

    def reset
      self.offsets = offsets.clear
    end
  end

  class ANSI::Callbacks
    property block_or_nil : Hokusai::Block? = nil
    property canvas_or_nil : Hokusai::Canvas? = nil
    property height : Float32 = 0f32
    property color_offsets = ColorOffsets.new

    getter default_color = [233,233,233]
    getter default_style = Style::Normal

    getter style_stack = [] of Bool
    property color_start = 0
    property color_stop = 0
    property current_color : Color { default_color }
    property current_style : Style { default_style }
    property text_buffer = ""

    property on_print : Proc(Callbacks, Nil) = ->(callbacks : Callbacks) {}

    def print
      on_print.call(self)
    end

    def on_line(&block : Proc(Callbacks, Nil))
      self.on_print = block
    end

    def <<(char : Char)
      self.text_buffer += char
      self.color_stop += 1
    end

    def commit_style
      color_offsets[(color_start...color_stop)] = {current_style, current_color} if (color_stop - color_start) > 0
      self.color_start = color_stop
      # self.color_stop += 1

      reset_color
      reset_style
    end

    def reset
      reset_color
      reset_style

      self.text_buffer = ""
      self.color_start = 0
      self.color_stop = 0
      self.style_stack.clear
      self.color_offsets.reset
    end

    def reset_color
      self.current_color = default_color
    end

    def reset_style
      self.current_style = default_style
    end

    def canvas=(canvas : Hokusai::Canvas)
      self.canvas_or_nil = canvas
    end

    def canvas : Hokusai::Canvas
      canvas_or_nil.try do |canvas|
        return canvas
      end

      raise "Need a canvas in the callbacks"
    end

    def block=(block : Hokusai::Block)
      self.block_or_nil = block
    end

    def block : Hokusai::Block
      block_or_nil.try do |block|
        return block
      end
  
      raise "Need a block in the callbacks.  Set with parser.callbacks.block=(block)"
    end
  end
end
