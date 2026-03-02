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
    case Process.run("uname")
    in String => str
      expect(str.chomp).to eq "Linux"
    in e
      expect(e.success?).to eq false
      expect(e.ok?).to eq false
      expect(e.stdout).to eq ""
      expect(e.exit_code).to not_eq(0)
    end
  end

  it "print once Linux\n" do
    expect(Process.run("uname", out: $stdout)).to eq "Linux\n"
  end

  it "looks like ruby Open3 when bad" do
    case Process.run("echo good && echo bad >&2 && exit 1")
    in String => str
      expect(str.chomp).to eq "good"
    in e
      expect(e.stdout.chomp).to eq "good"
      expect(e.stderr.chomp).to eq "bad"
      expect(e.exit_code).to eq 1
    end
  end

  it "not raise by default when Exception" do
    expect { Process.run("unamea") }.not_to raise_error
    expect { Process.run("unamea", exception: true) }.to raise_error Errno::ENOENT
    expect { Process.run("./Rakefile") }.not_to raise_error
    expect { Process.run("./Rakefile", exception: true) }.to raise_error Errno::EACCES
    expect { Process.run("bash -c ./Rakefile") }.not_to raise_error
    expect { Process.run("bash -c ./Rakefile", exception: true) }.not_to raise_error
    expect { system("bash -c ./Rakefile") }.not_to raise_error
    expect { system("bash -c ./Rakefile", exception: true) }.to raise_error RuntimeError

    expect { Process.output("unamea") }.not_to raise_error
    expect { Process.output("unamea", exception: true) }.to raise_error Errno::ENOENT

    expect { Process.output("unamea") }.not_to raise_error
    expect { Process.output("unamea", exception: true) }.to raise_error Errno::ENOENT
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
    expect(Process.run("bash") { |pipe| pipe.puts "uname" }).to eq "Linux\n"
  end

  it "print and also log to file" do
    tempfile = Tempfile.new(["test_", ".log"])
    File.open(tempfile.path, "w") do |io|
      Process.run("uname", out: io)
    end

    expect(tempfile.readlines).to eq ["Linux\n"]
    tempfile.delete
  end

  it "write to multi IO" do
    tempfile1 = Tempfile.new(["test_", ".log"])
    tempfile2 = Tempfile.new(["test_", ".log"])

    File.open(tempfile1.path, "w") do |io1|
      File.open(tempfile2.path, "w") do |io2|
        expect(Process.run("uname", out: [io1, io2]).each_line.to_a).to eq ["Linux\n"]
      end
    end

    expect(tempfile1.readlines).to eq ["Linux\n"]
    expect(tempfile2.readlines).to eq ["Linux\n"]
    tempfile1.delete
    tempfile2.delete
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
