module Trollio::Console
  module AnsiErase
    macro included
      @[Hokusai::Target]
      def ansi_erase_in_display(*, value : Int32)
        buffer.erase_in_display(value)
      end

      @[Hokusai::Target]
      def ansi_erase_in_line(*, value : Int32)
        buffer.erase_in_line(value)
      end
    end
  end
end
