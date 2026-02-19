# frozen_string_literal: true

require "multi_io"
require "stringio"
require_relative "process/version"

module Process
  def self.run(*args, output: STDOUT, error: STDERR, **options)
    output_strio = StringIO.new
    error_strio = StringIO.new

    output_writter = if !output.is_a?(IO)
                       output
                     elsif output != STDOUT
                       MultiIO.new(STDOUT, output, output_strio)
                     else
                       MultiIO.new(STDOUT, output_strio)
                     end
    error_writter = if !error.is_a?(IO)
                      error
                    elsif error != STDERR
                      MultiIO.new(STDERR, error, error_strio)
                    else
                      MultiIO.new(STDERR, error_strio)
                    end

    # spawn don't support MultiIO nor StringIO
    in_r, in_w = IO.pipe
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe

    # override the options, so put the option after the options
    pid = spawn(*args, **options, in: in_r, out: out_w, err: err_w)

    if block_given?
      begin
        yield in_w, out_r, err_r
      rescue StandardError => e
        Process.detach(pid)
        raise e
      end
    end

    in_w.close
    out_w.close
    err_w.close

    out_r.each_line do |line|
      output_writter.write(line)
    end

    err_r.each_line do |line|
      error_writter.write(line)
    end

    in_r.close
    out_r.close
    err_r.close

    pid, status = Process.wait2(pid)

    output.close unless !output.is_a?(IO) || output == STDOUT
    error.close unless !error.is_a?(IO) || error == STDERR
    output_strio.close
    error_strio.close

    case status.success?
    when true
      output_strio.string
    else
      [output_strio.string, error_strio.string, status]
    end
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
