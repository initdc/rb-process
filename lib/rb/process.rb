# frozen_string_literal: true

require "multi_io"
require_relative "process/version"

module Process
  def self.run(*args, log_file: nil, **options)
    if log_file && !log_file.is_a?(File)
      raise ArgumentError.new("log_file must be a File with mode")
    end

    mio = log_file ? MultiIO.new($stdout, log_file) : $stdout
    result = String.new

    IO.popen(*args, **options) do |pipe|
      if block_given?
        yield pipe
        pipe.close_write
      end
      while !pipe.eof
        line = pipe.gets
        mio.write(line)
        result << line
      end
    end

    log_file.close if log_file
    result
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
