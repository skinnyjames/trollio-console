require "yaml"

module Trollio::Console
  class Theme
    include YAML::Serializable
    
    @[YAML::Field]
    property background_color : Array(Int32) = [40, 42, 54]

    @[YAML::Field]
    property selection_color : Array(Int32) = [23,25,35]

    @[YAML::Field]
    property prompt_color : Array(Int32) = [248, 248, 242]

    @[YAML::Field]
    property outline_color : Array(Int32) = [68, 71, 90]

    @[YAML::Field]
    property font_size : Int32 = 16

    def self.from_file(path : String | Path)
      from_yaml(File.read(path.to_s))
    end

    def self.default
      yaml = <<-EOF
      ---
      background_color: [40,42,54]
      prompt_color: [248, 248, 242]
      outline_color: [68, 71, 90]
      selection_color: [23,25,35]
      EOF

      from_yaml(yaml)
    end
  end
end
