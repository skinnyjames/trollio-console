module Trollio::Console::Blocks
  class Prompt < Hokusai::Block
    @@template = <<-EOF
    [template]
      dynamic { @size_updated="dynamic_update_size" }
        rect
          empty  
    EOF
    
    uses(
      dynamic: Hokusai::Blocks::Dynamic,
      rect: Hokusai::Blocks::Rect,
      empty: Hokusai::Blocks::Empty
    )

    @[Hokusai::Target]
    def dynamic_update_size(*, width : Float32, height : Float32)
      emit("update_height", value: height)
    end
  end
end