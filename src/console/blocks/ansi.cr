require "../ansi/parser"

module Trollio::Console::Blocks
  class ANSI < Hokusai::Block
    @@template = <<-EOF
    [template]
      virtual
    EOF

    computed!(content, String)
    computed(size, Int32, 18)
    computed(selection_color, Array(Int32), [233,233,233])
    computed(padding, Array(Float32), [5f32, 5f32, 5f32, 5f32])
    computed(cursor_offset, Int32, 0)

    inject?(selection, selection, Hokusai::Util::Selection)
    inject?(panel_height, panel_height, Float32)
    inject?(panel_offset, panel_offset, Float32)

    property last_clamping : Hokusai::Clamping? = nil
    property last_content : String? = nil
    property last_size : Tuple(Float32, Float32)? = nil
    property click_position : {Float32, Float32}? = nil
    property last_cursor_offset : Int32? = nil
    property last_scroll_y : Float32? = nil
    property last_y : Float32? = nil
    
    getter parser : Console::ANSI::Parser do
      ansi_parser = Console::ANSI::Parser.new
      ansi_parser.callbacks.block = self
      ansi_parser
    end

    def draw_ansii(callbacks : Console::ANSI::Callbacks)
      block = callbacks.block
      canvas = callbacks.canvas

      callbacks.color_offsets.each do |range, (style, color)|
        text = callbacks.text_buffer[range]
        block.draw_with do |commands|
          commands.text(text, canvas.x, canvas.y) do |command|
            command.color(color)
          end
        end
      end
    end

    def render(canvas : Hokusai::Canvas, &)
      if last_content != content || last_size != {canvas.width, canvas.height}
        emit("cursor_reset")

        parser.callbacks.reset
        parser.process(content, canvas.clone)

        clamping = Hokusai.fonts.active.clamp(parser.callbacks.text_buffer, size, canvas.width - padding[1] - padding[3])

        self.last_clamping = clamping
        self.last_content = content
        self.last_size = {canvas.width, canvas.height}
      else
        # puts ["other", canvas.y, canvas.height]
        clamping = last_clamping.not_nil!
      end


      iterator = Hokusai::Util::ClampingIterator.new(clamping, canvas.x + padding[3], canvas.y + padding[0])
      boundary = {canvas.y, canvas.y + canvas.height}
      offset_y = panel_offset || 0f32

      # Register iterator callbacks
      iterator.on_draw do |text, x, y, segment|
        new_x = x
        parts = parser.callbacks.color_offsets.split(segment.offset, segment.size)
        selection.try do |selector|
          # set the initial cursor
          if cursor_offset.zero? && !selector.started
            selector.cursor = {x, y + offset_y, 0f32, size.to_f32}
            
            self.last_cursor_offset = cursor_offset
          end
        end

        if parts.empty?
          draw do
            text(text, x, y) do |command|
              command.color([244,244,244])
              # command.color(parser.callbacks.default_color)
              command.size(size)
            end
          end
        end

        parts.each do |range, style, color|
          if style.bold?
            Hokusai.fonts.activate "monaco_bold"
          else
            Hokusai.fonts.activate "monaco"
          end

          segment_width = segment.width((range.begin - segment.offset...range.end - segment.offset))

          draw do
            if style.underline?
              rect(new_x, y, segment_width, size.to_f32) do |command|
                command.outline(1f32)
                command.outline_color(color)
                command.outline_position([false, false, true, false])
              end
            end

            text(clamping.text[range], new_x, y) do |command|
              command.color(color)
              command.size(size)
            end
          end

          new_x += segment_width
        end

        Hokusai.fonts.activate "monaco"
      end

      iterator.on_draw_selection do |x, y, width, height|
        draw do
          rect(x, y, width, height) do |command|
            command.color(selection_color)
          end
        end
      end
  
      iterator.on_selection_change do |start, stop|
        emit("selected", start: start, stop: stop)
      end

      iterator.on_cursor_change do |x, y, w, h|
        selection.try do |selector|
          selector.cursor = {x, y + offset_y, w, h}
        end
      end

      iterator.on_char do |char, hit_box, offset|
        selection.try do |selector|
          # # change the cursor if the offset is different
          if offset == cursor_offset.try(&.-(1))
            # puts ["match", offset, cursor_offset, (last_cursor_offset != cursor_offset || last_content != content || last_scroll_y != offset_y)]
            if (last_cursor_offset != cursor_offset || last_content != content || last_scroll_y != offset_y)
              selector.cursor = {hit_box.shift_right(2).x, hit_box.y, hit_box.width, hit_box.height}
      
              self.last_cursor_offset = cursor_offset
              self.last_scroll_y = offset_y
            end
          end

          # change the cursor if a char was clicked
          # click_position.try do |click_x, click_y|
          #   # next if selector.type.frozen?

          #   if hit_box.shift_right.includes_x(click_x) && hit_box.includes_y(click_y)
          #     selector.cursor = {hit_box.shift_right(2).x, hit_box.y + offset_y, hit_box.width, hit_box.height}

          #     if offset + 1 != last_cursor_offset
          #       emit("select_offset", value: offset + 1)
          #       self.last_cursor_offset = offset + 1
          #     end

          #     self.click_position = nil
          #   end
          # end
        end
      end

      while segment = iterator.next
        break if segment.is_a?(Iterator::Stop)

        segment.draw(size, boundary, selection: selection)
      end
    
      emit("rendered", value: iterator.clamping.text.size)
      emit("height_updated", value: iterator.height + padding[0] + padding[2])

      yield(canvas)
    end
  end
end
