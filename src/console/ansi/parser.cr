require "./callbacks"
require "../../lib/vtparse"

module Trollio::Console
  class ANSI::Parser
    alias Action = VTParse::Action
    alias State = VTParse::State

    getter callbacks : Callbacks = Callbacks.new
    getter vt_parser : VTParse::Parser

    def initialize(debug = false)
      VTParse.init(out vt_parser, on_parse)

      @vt_parser = vt_parser
    end

    def process(content : String, canvas : Hokusai::Canvas)
      callbacks.canvas = canvas

      void = Box(Callbacks).box(callbacks)
      vt_parser.user_data = void

      address = pointerof(@vt_parser)

      VTParse.parse(address, content, content.size)
    end

    def debug_parse
      ->(parser : VTParse::Parser*, action : VTParse::Action, codepoint : LibC::UInt) do
        params = [] of Int32

        (0...parser.value.num_params).each do |index|
          params << parser.value.params[index]
        end

        output = String.build do |io|
          io.puts "Action: #{action} #{VTParse::State.new(parser.value.state)}"
          io.puts "Codepoint: #{codepoint.chr.inspect} [#{codepoint}]"
          io.puts "Params: #{params.inspect}"
          io.puts "Intermmediate chars: #{parser.value.num_intermediate_chars}"
          io.puts "\n"
        end

        STDOUT.puts(output)
      end
    end

    def on_parse
      ->(parser : VTParse::Parser*, action : VTParse::Action, codepoint : LibC::UInt) do
        renderer = Box(Callbacks).unbox(parser.value.user_data)

        params = [] of Int32
        (0...parser.value.num_params).each do |i|
          params << parser.value.params[i]
        end

        case action
        when Action::PRINT
          case parser.value.state
          when State::GROUND
            renderer.block.emit("cursor_forward", value: 1)
            renderer << codepoint.chr
          else
            puts "catchall for PRINT"
            # catchall for PRINT
          end
        when Action::EXECUTE
          case parser.value.state
          when State::GROUND
          case codepoint.chr
          when '\a'
            renderer.block.emit("bell")
            return
          when '\n'
            renderer.block.emit("cursor_down", value: 1)
          when '\b'
            renderer.block.emit("cursor_back", value: 1)
            return
          end
            # puts "EXECute: #{codepoint.chr.inspect}"
            renderer << codepoint.chr
            renderer.commit_style unless renderer.color_offsets.empty?
          else
            puts "catchall for EXECUTE"
            # catchall for EXECUTE
          end
        when Action::OSC_PUT
          case parser.value.state
          when State::OSC_STRING
            # append the string to the buffer.
            
          else
            puts "catchall for OSC_PUT"

            # catchall for OSC_PUT
          end
        when Action::OSC_END
          case parser.value.state
          when State::OSC_STRING
          else
            # catchall for OSC_END
            puts ["OSC END: #{codepoint.chr}"]
          end
        when Action::CSI_DISPATCH
          case parser.value.state
          when State::CSI_ENTRY
            case codepoint.chr
            when '?'
              puts ["private", params]
            when 's'
              puts ["save cursor"]
            when 'u'
              puts ["restore cursor"]
            when 'h'
              puts ["show cursor", params]
            when 'A'
              puts ["cursor up", params]
            when 'B'
              puts ["cursor_ down", params]
            when 'C'
              puts ["cursor forward", params]
            when 'D'
              puts ["cursor back", params]
            when 'E'
              puts ["cursor next", params]
            when 'F'
              puts ["cursor prev", params]
            when 'J'
              puts ["erase in display", params]
            when 'K' # erase in line
              puts ["erase in line", params]
              renderer.block.emit("erase_in_line", value: params[0]? || 0)

            when 'M' # cursor position
              puts ["cursor pos", params]
            when 'H'
              renderer.block.emit("erase_in_display", value: params[0]? || 2)
            else
              # puts "catchall csi: #{codepoint.chr}"

              renderer.style_stack.pop?

              renderer.commit_style if renderer.style_stack.empty?
            end
          when State::CSI_PARAM
            case codepoint.chr
            when 'm'
              renderer.commit_style if renderer.style_stack.empty?
              renderer.style_stack << true
              case params[0]?
              when 0, .nil?
                renderer.reset_color
                renderer.reset_style
              when 1
                renderer.current_style = Style::Bold
              when 4
                renderer.current_style = Style::Underline
              when (30...39)
                params[0].try do |color_index|
                  renderer.current_color = SIMPLE_COLORS[color_index] || COLORS[color_index]
                end
              else
                # catchall for not implemented sgr color value
                puts "Not implemented: #{codepoint.chr} #{params[0]?.inspect}"
              end
            when 'J'
              case params[0]?
              when .nil?
              when 2
                renderer.block.emit("clear")
              else
                # catchall for not implemented J SGR functions
                puts ["SGR J", params[0]?]
              end
            when 'h', 'j'
              renderer.block.emit("set_mode", function: codepoint.chr, value: params[0]?)
            else
              # catchall for not implemented sgr functions
              puts ["CSI PARAM #{codepoint.chr}", params[0]?]
            end
          else
            # catchall for CSI_DISPATCH
            puts ["CSI #{codepoint.chr} catchall", params]
          end
        end
      end
    end
  end
end
