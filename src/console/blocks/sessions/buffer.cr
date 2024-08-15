module Trollio::Console
  class Buffer
    property rows : Array(Array(Char)) do
      init = [] of Array(Char)
      init << [] of Char
      init
    end

    property current_row : Int32 = 0
    property current_col : Int32 = 0
    property offset : Int32 = 0

    def reset_cursor
      self.current_row = 0
      self.current_col = 0
      self.offset = 0
    end

    def add(ansi : String)
      index = 0
      max = ansi.size

      while index < max
        case ansi[index]
        when '\r'
          self.current_col = 0
        when '\n'
          self.current_row += 1
          rows << [] of Char
        else
          self.current_col += 1
          self.offset += 1
          rows[current_row] << ansi[index]
        end

        index += 1
      end
    end

    def move_cursor_to_end
      self.current_row = rows.size - 1
      self.current_col = rows[-1].size - 12
    end

    def erase_in_display(mode : Int32)
      case mode
      when 0
        puts "erase in display {0}"
      when 1
        puts "erase in display {1}"
      when 2
        self.rows = [rows[-1]]
        self.current_row = 0
      end
    end

    def erase_in_line(mode : Int32)
      case mode
      when 0
        rows[current_row] = rows[current_row][0...current_col]
        self.current_col = rows[current_row].size - 1
      when 1
        rows[current_row] = rows[current_row][current_col..-1]
        self.current_col = rows[current_row].size - 1
      when 2
      end
    end

    def to_s
      rows.map(&.join("")).join("\r\n")
    end
  end
end