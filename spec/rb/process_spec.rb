# frozen_string_literal: true

require "tempfile"

RSpec.describe Process do
  it "has a version number" do
    expect(Process::VERSION).not_to be nil
  end

  it "print lines" do
    Process.run("sudo apt update")
  end

  it "support $stdin when no block given" do
    Process.run("uname", in: $stdin)
  end

  it "get command output but also print" do
    r = Process.run("uname")
    expect(r.success?).to eq true
    expect(r.ok?).to eq true
    expect(r.stdout).to eq "Linux\n"
    expect(r.exit_code).to eq 0
    expect(r.pid).to eq r.status.pid
  end

  it "not raise by default when Errno::ENOENT" do
    expect { Process.run("unamea") }.not_to raise_error
    expect { Process.run("unamea", exception: true) }.to raise_error
  end

  it "get the output and not print" do
    expect(Process.output("uname").chomp).to eq "Linux"
  end

  it "return nil when exec not success" do
    expect(Process.output("unamea")).to be_nil
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

  # https://devdocs.io/ruby~3.4/io#class-IO-label-Reading
  it "responds to methods" do
    Process.run("bash", out: File.open(File::NULL, "r+")) do |pipe|
      pipe.write_nonblock("echo")
      pipe << " "
      pipe.write("hello ")
      pipe.print("w")
      pipe.printf("%s", "o")
      pipe.putc "r"
      pipe.write("l")
      pipe.puts "d"
      pipe.close_write

      pipe.getbyte
      pipe.getc
      pipe.readbyte
      pipe.readchar
      pipe.readpartial(1)
      pipe.readline
      pipe.readlines
      pipe.gets
      pipe.read
    end
  end
end
