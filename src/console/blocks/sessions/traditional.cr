require "../../sessions/pty"
require "../../sessions/command"
require "../command"
require "../ansi"
require "./buffer"
require "./ansi_cursor"
require "./ansi_erase"
 
module Trollio::Console
  class Sessions::Traditional < Hokusai::Block
    @@template = <<-EOF
    [template]
      panel {
        @scroll="goto_clear"
        :scroll_goto="scroll_goto"
        @keypress="buffer_keypress"
      }
        ansi {
          :content="buffer_text"
          :height="buffer_height"
          text_color="233,233,233"
          :selection_color="selection_color"
          cursor_color="255,92,87"
          :cursor_offset="last_offset"
          :outline_color="outline_color""
          outline="1"
          outline_top="true"
          padding="15,15,15,15"
          :size="font_size"
          @bell="ansi_bell"
          @cursor_reset="ansi_cursor_reset"
          @cursor_up="ansi_cursor_up"
          @cursor_down="ansi_cursor_down"
          @cursor_forward="ansi_cursor_forward"
          @cursor_back="ansi_cursor_back"
          @cursor_next_line="ansi_cursor_next_line"
          @cursor_prev_line="ansi_cursor_prev_line"
          @cursor_position="ansi_cursor_position"
          @erase_in_display="ansi_erase_in_display"
          @erase_in_line="ansi_erase_in_line"
          @scroll_up="ansi_scroll_up"
          @scroll_down="ansi_scroll_down"
          @set_mode="ansi_set_mode"
          @rendered="set_buffer_offset"
          @clear="clear_results"
          @height_updated="buffer_update_height"
        }
    EOF

    include AnsiCursor
    include AnsiErase
  
    uses(
      multiplex: Multiplex,
      input: Hokusai::Blocks::Input,
      empty: Hokusai::Blocks::Empty,
      panel: Hokusai::Blocks::Panel,
      command: Blocks::Command,
      ansi: Blocks::ANSI,
      vblock: Hokusai::Blocks::Vblock,
      rect: Hokusai::Blocks::Rect,
      text: Hokusai::Blocks::Text
    )

    inject(:theme, :theme, Theme)
    inject(:sessions, :sessions, Array(String))
    computed(outline_color, Array(Int32), theme.outline_color, true)
    computed(selection_color, Array(Int32), theme.selection_color, true)
    computed(font_size, Int32, theme.font_size, true)

    getter done : Channel({String?, Bool}) = Channel({String?, Bool}).new

    property io : Pty? = nil
    property buffer : Buffer = Buffer.new
    property buffer_offset : Int32 = 0
    property ansi_buffer_height : Float32 = 0f32
    property goto : Bool = false
    property goto_y : Float32 = 0f32

    @[Hokusai::Target]
    def ansi_bell
      emit("bell")

      buffer.remove_bell
    end

    @[Hokusai::Target]
    def ansi_set_mode(*, function : Char, value : Int32)
      case function
      when 'l'
        pty.io.noecho!
      when 'h'
        pty.io.echo!
      end
    end

    @[Hokusai::Target]
    def ansi_scroll_up(*, value : Int32)
    end

    @[Hokusai::Target]
    def ansi_scroll_down(*, value : Int32)
    end

    @[Hokusai::Target]
    def buffer_update_height(*, value : Float32)
      self.ansi_buffer_height = value + 30
      self.goto_y = value + 30
    end

    @[Hokusai::Target]
    def set_buffer_offset(*, value : Int32)
      self.buffer.offset = value
    end

    @[Hokusai::Target]
    def buffer_keypress(*, event : Hokusai::KeyPressEvent)
      if event.shift && (event.super || event.ctrl)
        case event.key
        when Hokusai::Key::V
          emit("new_session", vertical: true)
        when Hokusai::Key::H
          emit("new_session", vertical: false)
        end
        return
      end

      case event.key
      when Hokusai::Key::TAB
        pty.io.print("\t")
        pty.io.flush
      when Hokusai::Key::BACKSPACE
        pty.io.print("\b")
        pty.io.flush
      when Hokusai::Key::ENTER
        pty.io.print("\n")
        pty.io.flush
      else
        pty.io.print(event.char)
        pty.io.flush
      end
    end

    @[Hokusai::Target]
    def goto_clear
      self.goto = false
    end

    @[Hokusai::Method]
    def last_offset
      buffer.offset
    end
    
    @[Hokusai::Method]
    def buffer_text
      buffer.to_s
    end

    @[Hokusai::Method]
    def scroll_goto
      goto_y if goto
    end

    @[Hokusai::Method]
    def buffer_height
      ansi_buffer_height
    end

    # def render(canvas : Hokusai::Canvas, &)
    #   puts ["cavans", canvas.y, canvas.height]
    #   yield(canvas)
    # end

    def on_mounted
      command = "/bin/bash"
      puts dump

      @io = Trollio::Console::Pty.fork(command, io_env)

      spawn io_start(done, pty.io)
      spawn io_output_handle(done)

      emit("focus")
    end

    def on_resize(canvas : Hokusai::Canvas)  
      letter_width, letter_height = Hokusai.fonts.active.measure("a", font_size)
    
      rows = ((canvas.width - 30) / (letter_height)).ceil.to_u32
      cols = ((canvas.height - 30) / (letter_width)).ceil.to_u32

      pty.set_size(rows, cols, letter_width, letter_height)
    end

    def pty
      @io.try do |pty|
        return pty
      end

      raise Trollio::Error.new("No PTY on #{self.class}")
    end
    
    private def io_env : Hash(String, String)
      {
        "TERM" => "xterm-color",
        "CLICOLOR" => "1"
      }
    end

    private def io_start(done, reader, error = false)
      loop do
        slice = Bytes.new(1024)
        output = String.build do |io|
          size = reader.read(slice)
          while !size.zero?
            last = slice.index do |char|
              char == 0
            end

            last = last || -1
            io.print String.new(slice[0...last])

            break if slice[-3]? == 0
            
            slice.fill(0)

            size = reader.read(slice)
          end
        end

        done.send({output, error})
      end
    end

    private def io_output_handle(fin)
      loop do
        result = fin.receive
        result[0]?.try do |output|
          puts [output]
          self.buffer.add(output)

          self.goto_y = ansi_buffer_height
          self.goto = true
        end
      end
    end
  end
end
