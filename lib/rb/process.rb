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
      @status.respond_to?(name) ? @status.send(name, *args, &block) : super
    end

    def respond_to_missing?(name, include_private = false)
      @status.respond_to?(name, include_private) || super
    end

    def exit_code
      status.exitstatus
    end

    def success?
      status.success?
    end

    alias_method :ok?, :success?
  end

  def self.run(*args, out: $stdout, err: $stderr, exception: false, **options)
    stdout_reader, stdout_writer  = IO.pipe
    stderr_reader, stderr_writer  = IO.pipe
    childs_io = [stdout_writer, stderr_writer]
    parent_io = [stdout_reader, stderr_reader]

    out_strio = StringIO.new
    err_strio = StringIO.new
    out_multiwriter = IO::MultiWriter.new(out, out_strio)
    err_multiwriter = IO::MultiWriter.new(err, err_strio)

    if block_given?
      stdin_reader, stdin_writer = IO.pipe
      stdin_writer.sync = true
      childs_io << stdin_reader
      parent_io << stdin_writer

      pid = Process.spawn(*args, **options, in: stdin_reader, out: stdout_writer, err: stderr_writer)
      childs_io.each(&:close)

      pipe = IO::Stapled.new(stdout_reader, stdin_writer)
      begin
        yield pipe
      ensure
        stdin_writer.close unless stdin_writer.closed?
        pipe.close
      end
    else
      pid = Process.spawn(*args, **options, out: stdout_writer, err: stderr_writer)
      childs_io.each(&:close)
    end

    t1 = Thread.new do
      stdout_reader.each_line do |line|
        out_multiwriter.write(line)
      end
    end

    t2 = Thread.new do
      stderr_reader.each_line do |line|
        err_multiwriter.write(line)
      end
    end

    begin
      t1.join
      t2.join
    ensure
      out_multiwriter.close
      err_multiwriter.close
      parent_io.each { |io| io.close unless io.closed? }
    end

    pid, status = Process.wait2(pid)
    Result.new(out_strio.string, err_strio.string, status)
  rescue Errno::ENOENT => e
    raise e if exception

    Result.new(nil, nil, $?)
  end

  def self.output(*args, **options)
    stdout_reader, stdout_writer = IO.pipe
    pid = Process.spawn(*args, **options, out: stdout_writer)
    stdout_writer.close

    pid, status = Process.wait2(pid)
    if status.exited? && status.success?
      stdout_reader.read
    else
      nil
    end
  rescue Errno::ENOENT
    nil
  ensure
    stdout_reader.close
  end

  def self.code(...)
    pid, status = Process.wait2(spawn(...))
    status.exitstatus
  rescue Errno::ENOENT
    127
  end
end
