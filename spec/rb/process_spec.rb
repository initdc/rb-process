# frozen_string_literal: true

require "tempfile"

RSpec.describe Process do
  it "has a version number" do
    expect(Process::VERSION).not_to be nil
  end

  it "print lines" do
    Process.run("sudo apt update")
  end

  it "get command output but also print" do
    r = Process.run("uname")
    expect(r.success?).to eq true
    expect(r.ok?).to eq true
    expect(r.stdout).to eq "Linux\n"
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
    expect(Process.run("bash") { |pipe| pipe.puts "uname" }.stdout).to eq "Linux\n"
  end

  it "print and also log to file" do
    tempfile = Tempfile.new(["test_", ".log"])
    File.open(tempfile.path, "w") do |io|
      Process.run("uname", out: io)
    end

    expect(tempfile.readlines).to eq ["Linux\n"]
    tempfile.delete
  end
end
