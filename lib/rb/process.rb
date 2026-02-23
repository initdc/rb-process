# frozen_string_literal: true

require "stringio"
require_relative "io"
require_relative "process/version"

module Process
  class Result
    attr_reader :stdout
    attr_reader :stderr
    attr_reader :status

    def initialize(stdout, stderr, status)
      @stdout = stdout
      @stderr = stderr
      @status = status
    end

    def method_missing(name, *args, &block)
      @status.send(name, *args, &block)
    end

    def respond_to_missing?(name, include_private = false)
      super || @status.respond_to?(name, include_private)
    end

    def exit_code
      status.exitstatus
    end

    def success?
      status.success?
    end

    alias_method :ok?, :success?
  end

  def self.run(*args, out: $stdout, err: $stderr, **options)
    in_r, in_w = IO.pipe
    in_w.sync = true
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe

    child_io = [in_r, out_w, err_w]
    parent_io = [in_w, out_r, err_r]

    output_strio = StringIO.new
    error_strio  = StringIO.new
    output_writter = IO::MultiWriter.new(out, output_strio)
    error_writter = IO::MultiWriter.new(err, error_strio)

    pid = Process.spawn(*args, **options, in: in_r, out: out_w, err: err_w)
    child_io.each(&:close)

    if block_given?
      pipe = IO::Stapled.new(out_r, in_w)
      begin
        yield pipe
      ensure
        in_w.close unless in_w.closed?
        pipe.close
      end
    end

    t1 = Thread.new do
      out_r.each_line do |line|
        output_writter.write(line)
      end
    end

    t2 = Thread.new do
      err_r.each_line do |line|
        error_writter.write(line)
      end
    end

    begin
      t1.join
      t2.join
    ensure
      output_writter.close
      error_writter.close
      parent_io.each { |io| io.close unless io.closed? }
    end

    pid, status = Process.wait2(pid)
    Result.new(output_strio.string, error_strio.string, status)
  end

  def self.output(...)
    IO.popen(...).read
  end

  def self.code(...)
    pid, status = Process.wait2(spawn(...))
    status.exitstatus
  rescue Errno::ENOENT
    127
  end
end
