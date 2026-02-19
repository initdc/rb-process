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
    expect(Process.run("uname")).to eq "Linux\n"
  end

  it "print once Linux\n" do
    expect(Process.run("uname", output: STDOUT)).to eq "Linux\n"
  end

  it "looks like ruby Open3 when bad" do
    r = Process.run("echo good && echo bad >&2 && exit 1")
    case r
    when String
      expect(r.chomp).to eq "good"
    else
      o, e, s = r
      expect(o.chomp).to eq "good"
      expect(e.chomp).to eq "bad"
      expect(s.exitstatus).to eq 1
    end
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
    expect(Process.run("bash") { |i, _o, _e| i.puts "uname" }).to eq "Linux\n"
  end

  it "print and also log to file" do
    tempfile = Tempfile.new(["test_", ".log"])
    Process.run("uname", output: File.open(tempfile.path, "w"))

    expect(tempfile.readlines).to eq ["Linux\n"]
    tempfile.delete
  end
end
