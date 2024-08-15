require "./spec_helper"

describe Trollio::Console do
  it "executes commands" do
    with_app(Trollio::Console::Main) do |client|
      prompt = client.block("#prompt")
      prompt.write("pwd")

      client.block("#output").attr("content").as_s.should contain("trollio-console")
      client.block("#result text").attr("content").as_s.should eq("pwd\n")
    end
  end
end