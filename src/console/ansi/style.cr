module Trollio::Console
  module ANSI
    alias Color = Array(Int32)

    enum Style
      Normal
      Bold
      Italics
      BoldItalics
      Underline

      def normal?
        self == Style::Normal
      end

      def underline?
        self == Style::Underline
      end

      def bold?
        self == Style::Bold
      end
    end

    SIMPLE_COLORS = {} of Int32 => Color
    COLORS = {} of Int32 => Color
    FOREGROUND_COLORS = {} of Int32 => Color
  
    SIMPLE_COLORS[30] = [0,0,0]         # black
    SIMPLE_COLORS[31] = [226,81,144]    # red
    SIMPLE_COLORS[32] = [102,206,99]    # green
    SIMPLE_COLORS[33] = [206,202,99]    # yellow
    SIMPLE_COLORS[34] = [131,207,234]   # blue
    SIMPLE_COLORS[35] = [198, 93, 191]  # magenta
    SIMPLE_COLORS[36] = [133,220,252]   # cyan
    SIMPLE_COLORS[37] = [233, 233, 233] # white
  
    (0..5).each do |red|
      (0..5).each do |green|
        (0..5).each do |blue|
          c = 16 + (red * 36) + (green * 6) + blue
          r = red > 0 ? red * 40 + 55 : 0
          g = green > 0 ? green * 40 + 55 : 0
          b = blue > 0 ? blue * 40 + 55 : 0
          COLORS[c] = [r, g, b]
        end
      end
    end
  end
end
