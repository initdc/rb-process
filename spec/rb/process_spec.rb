# frozen_string_literal: true

RSpec.describe Process do
  it "has a version number" do
    expect(Process::VERSION).not_to be nil
  end

  it "print lines" do
    Process.run("sudo apt update")
  end

  it "get command output but also print" do
    expect(Process.run("uname")).to eq "Linux\n"
  end

  it "get the output and not print" do
    expect(Process.output("uname").chomp).to eq "Linux"
  end

  it "get array by method chaining" do
    expect(Process.output("ls spec").each_line(chomp: true).to_a).to eq ["rb", "spec_helper.rb"]
  end

  it "get exit code" do
    expect(Process.code("uname -s")).to eq 0
  end

  it "answer with cmd with ruby style" do
    expect(Process.run("bash", "r+") { |pipe| pipe.puts "uname" }).to eq "Linux\n"
  end
end
