require "hokusai/ui/src/hokusai"
require "hokusai/ui/src/hokusai/backends/raylib"
require "hokusai/ui/src/hokusai/blocks/*"
require "hokusai/ui/src/hokusai/automation/*"
require "../src/console"
require "spec"

def with_app(app : Hokusai::Block.class, &)
  backend = Hokusai::Backends::RaylibBackend.new do |config|  
    config.automate
    config.automation_driver = Hokusai::Automation::Driver.new
  
    config.after_load do
      monaco = Hokusai::Backends::RaylibBackend::Font.from_ext("#{__DIR__}/Monaco.ttf", 32, STR)
      monaco_bold = Hokusai::Backends::RaylibBackend::Font.from_ext("#{__DIR__}/MonacoB2.ttf", 32, STR)
  
      Hokusai.fonts.register "monaco", monaco
      Hokusai.fonts.register "monaco_bold", monaco_bold
      Hokusai.fonts.activate "monaco"
    end
  
    config.width = 600
    config.height = 500
    config.title = "Trollio Console (test)"
  end
  
  spawn do
    backend.run(app)
  end

  client = Hokusai::Automation::Client.new
  yield client
end