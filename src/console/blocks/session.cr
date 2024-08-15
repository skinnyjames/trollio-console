# require "../sessions/pty"
# require "../sessions/command"
# require "./command"
# require "./ansi"
# require "string_scanner"

# module Trollio::Console::Blocks
#   class Session < Hokusai::Block
#     @@template = <<-EOF
#     [template]
#       selectable {
#         cursor_color="255,92,87"
#       }
#         panel { 
#           @scroll="goto_clear"
#           :scroll_goto="goto_bottom"
#         }
#           [for="command in results"]
#             command {
#               @clear="clear_results"
#               :height="command_height(index, command)"
#               :selection_color="selection_color"
#               :size="font_size"
#             }
#       ansi {
#         :content="prompt"
#         height="50"
#         text_color="233,233,233"
#         :text_selection_color="selection_color"
#         cursor_color="255,92,87"
#         :outline_color="outline_color""
#         outline="1"
#         outline_top="true"
#         padding="15,15,15,15"
#         size="20"
#         @change="run_command"
#         @keypress="handle_special_keypress"
#       }
#     EOF
  
#     uses(
#       input: Hokusai::Blocks::Input,
#       empty: Hokusai::Blocks::Empty,
#       panel: Hokusai::Blocks::Panel,
#       selectable: Hokusai::Blocks::Selectable,
#       command: Blocks::Command,
#       ansi: Blocks::ANSI,
#       vblock: Hokusai::Blocks::Vblock
#     )

#     inject(:theme, :theme, Theme)
#     computed(outline_color, Array(Int32), theme.outline_color, true)
#     computed(selection_color, Array(Int32), theme.selection_color, true)
#     computed(font_size, Int32, theme.font_size, true)

#     # getter input : IO::Pty
#     # getter output : IO::Pty
#     # getter error_output : IO::Pty
#     getter done : Channel({String?, Bool}) = Channel({String?, Bool}).new
#     getter commands : Array(Sessions::Command) = [] of Sessions::Command
#     property command_heights : Hash(Int32, Float32) = {} of Int32 => Float32
#     # property process : Process
#     property last_bottom : Float32? = nil
#     property goto : Bool = false
#     property decrement : Int32 = 0
#     property inited : Bool = false
#     property buffer : String = ""
#     property last_prompt : String? = nil
#     property typing_started : Bool = false
#     property input_count : Int32 = 0
#     property input_buffer : String = ""

#     @pty : Pty? = nil

#     @[Hokusai::Target]
#     def clear_results
#       commands.clear
#     end

#     def pty : Pty
#       @pty.try do |pty|
#         return pty
#       end

#       raise "Bad"
#     end

#     # @[Hokusai::Target]
#     # def run_command(*, value : String)
#     #   self.commands << Sessions::Command.new(command: value)

#     #   # input.raw do |raw|
#     #   #   raw.puts(value)
#     #   # end

#     #   self.goto = true
#     # end

#     @[Hokusai::Target]
#     def handle_special_keypress(*, event : Hokusai::KeyPressEvent)
#       if !typing_started
#         self.buffer += "HOKU_COMMAND_START"
#         self.typing_started = true
#       end

#       begin
#         case event.shift
#         when true
#           case event.key
#           when Hokusai::Key::UP
#             pty.io.print("\b")
#           when Hokusai::Key::DOWN
#             puts "Down!!"
#             STDIN.raw(&.print("d"))
#             return
#           when Hokusai::Key::LEFT
#             pty.io.puts("^[1;2D")
#           when Hokusai::Key::RIGHT
#             pty.io.puts("^[1;2C")
#           end
#         when false
#           case event.key
#           when Hokusai::Key::ENTER
#             puts "printing newline"
#             # self.buffer += input_buffer
#             self.buffer += "HOKU_COMMAND_END"
        
#             puts "SENDING NEWLINE: #{self.buffer}"
#             pty.io.print("\n")
#             pty.io.print("HOKU_END\b\b\b\b\b\b\b\b")
#             pty.io.flush

#             self.input_count = 0
#             self.last_prompt = nil
#             self.input_buffer = ""
#             self.typing_started = false
#             return

#           when Hokusai::Key::BACKSPACE
#             pty.io.print("\b")
#           else
#             self.input_buffer += event.char
#             pty.io.print(event.char)
#           end
#         end
#       rescue ex
#         puts Errno.value
#       end

#       pty.io.flush
#     end

#     @[Hokusai::Target]
#     def goto_clear
#       self.goto = false
#     end

#     @[Hokusai::Method]
#     def prompt
#       self.last_prompt || ""
#     end

#     @[Hokusai::Method]
#     def results      
#       puts ["bufferf", buffer]
#       # puts ["commands", commands.inspect]
#       return commands unless buffer =~ /HOKU_END/

#       chunks = buffer.split("\r\n")
#       prompt, stuff = chunks.partition { |str| str =~ /HOKU_END/ }

#       self.last_prompt = prompt.join("").gsub(/ HOKU_END/, "")

#       if stuff.join("\r\n") =~ /HOKU_COMMAND_END/
#         input = stuff.join("\r\n").split(/HOKU_COMMAND_START/)
#         cmd, output = input[1].split(/HOKU_COMMAND_END/)
#         commands << Sessions::Command.new(command: cmd, output: output)
#       else
#         commands << Sessions::Command.new(command: nil, output: stuff.join("\r\n").lstrip)
#       end

#       self.buffer = ""

#       # i = 0
#       # while chunk = chunks.shift?
#       #   if chunk =~ /HOKU_COMMAND_END/
#       #     if i == chunks.size - 1
#       #       puts "heyy"
#       #     end
    
#       #     puts "Fuckkkk #{chunk}"
#       #     command, *rest = chunk.split(/HOKU_COMMAND_END/)

#       #     puts [i, command, rest]
#       #     commands << Sessions::Command.new(command: command, output: rest.join(""))
#       #   else
#       #     if i == chunks.size - 1
#       #       # rip out the prompt and the end delimiter
            
#       #     end

#       #     puts [i, chunk]
#       #     commands << Sessions::Command.new(command: nil, output: chunk.lstrip)
#       #   end
  
#       #   i += 1
#       # end

#       # self.buffer = ""

#       commands
#     end

#     @[Hokusai::Method]
#     def command_height(*, index : Int32, item : Hokusai::Value)
      
#       height = item.get(Sessions::Command).try(&.height)
#       # puts ["height: #{index} #{height}"]
#       height || 0f32
#     end

#     @[Hokusai::Method]
#     def results_height
#       res = commands.sum do |command|
#         command.height
#       end

#       puts ["res hieght", res]
#       res
#     end

#     @[Hokusai::Method]
#     def goto_bottom
#       if goto
#         going = goto
#         return last_bottom || 0f32
#       end
#     end

#     def on_resize(canvas : Hokusai::Canvas)  
#       letter_width, letter_height = Hokusai.fonts.active.measure("a", 20)
    
#       rows = ((canvas.width - 40) / (letter_height)).ceil.to_u32
#       cols = ((canvas.height - 30) / (letter_width)).ceil.to_u32

#       pty.set_size(rows, cols, letter_width, letter_height)
#     end

#     def on_mounted
#       children[1].node.meta.focus

#       puts dump
#     end

#     def render(canvas : Hokusai::Canvas)
#       self.last_bottom = canvas.y + canvas.height

#       yield(canvas)
#     end

#     def initialize(**args)
#       puts "hey"
#       pid, ptyio = Trollio::Console::Pty.fork
#       if pid.zero?
#         Process.exec(
#           "/bin/bash",
#           shell: false,
#           env: io_env
#         )
      
#         LibC.set_sid
#         sleep 2

#         exit(0)
#       end

#       puts "yeahhh"
#       @pty = ptyio.not_nil!
#       spawn io_start(done, pty.io)
#       spawn io_output_handle(done, commands)

#       sleep 1
#       self.buffer += "HOKU_END"
#       super(**args)
#     end

  
#     private def io_env : Hash(String, String)
#       {
#         "TERM" => "xterm-color",
#         "CLICOLOR" => "1"
#       }
#     end

#     private def io_start(done, reader, error = false)
#       loop do
#         slice = Bytes.new(1024)
#         output = String.build do |io|
#           size = reader.read(slice)
#           while !size.zero?
#             last = slice.index do |char|
#               char == 0
#             end

#             last = last || -1
#             io.print String.new(slice[0...last])

#             break if slice[-3]? == 0
            
#             slice.fill(0)

#             size = reader.read(slice)
#           end
#         end

#         done.send({output, error})
#         Fiber.yield
#       end
#     end

#     private def io_output_handle(done, commands)
#       loop do
#         Fiber.yield
#         result = done.receive

#         puts ["result", result]
#         result[0]?.try do |output|
#           self.buffer += output

#           # if commands[-1].command.nil?

#           # case commands
#           # when .empty?
#           #   commands << Sessions::Command.new(
#           #     output: output,
#           #     error: result[1],
#           #     index: 0
#           #   )
#           # else
#           #   if commands[-1].output.nil?
#           #     puts "assigning: ##{output}"
#           #     commands[-1].output = output
#           #   else
#           #     puts "appending: ##{output}"

#           #     commands[-1].output = commands[-1].output.not_nil! + output
#           #   end
#           #   commands[-1].error = result[1]
#           # end
#         end
#       end
#     end
#   end
# end
