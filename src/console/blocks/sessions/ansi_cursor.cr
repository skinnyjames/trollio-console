module Trollio::Console
  module AnsiCursor
    macro included
      @[Hokusai::Target]
      def ansi_cursor_reset
        buffer.reset_cursor
      end

      @[Hokusai::Target]
      def ansi_cursor_up(*, value : Int32)
      end

      @[Hokusai::Target]
      def ansi_cursor_up(*, value : Int32)
      end

      @[Hokusai::Target]
      def ansi_cursor_down(*, value : Int32)
        buffer.current_row += value
        buffer.current_col = 0
      end

      @[Hokusai::Target]
      def ansi_cursor_forward(*, value : Int32)
        buffer.current_col += value
      end

      @[Hokusai::Target]
      def ansi_cursor_back(*, value : Int32)
        buffer.current_col -= value
      end

      @[Hokusai::Target]
      def ansi_cursor_next_line(*, value : Int32)
      end

      @[Hokusai::Target]
      def ansi_cursor_prev_line(*, value : Int32)
      end

      @[Hokusai::Target]
      def ansi_cursor_position(*, row : Int32, col : Int32)
        self.cursor_row = row
        self.cursor_col = col

        puts "cursor pos moved"
      end
    end
  end
end