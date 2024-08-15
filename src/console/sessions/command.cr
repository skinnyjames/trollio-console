module Trollio::Console
  class Sessions::Command
    property :output, :command, :index, :error
    property height : Float32 = 0f32
  
    def initialize(
      @command : String? = nil,
      @output : String? = nil,
      @index : Int32 = 0,
      @error : Bool? = nil
    )
    end
  
    def hash(hasher)
      hasher = @command.hash(hasher)
      hasher = @output.hash(hasher)
      hasher
    end
  
    def to_json(io)
      {
        "command" => command,
        "output" => output,
        "error" => err,
        "index" => index
      }.to_json(io)
    end
  end
end
