# frozen_string_literal: true

require_relative "process/version"

module Process
  def self.run(*args, **options)
    result = String.new
    IO.popen(*args, **options) do |pipe|
      if block_given?
        yield pipe
        pipe.close_write
      end
      while !pipe.eof
        line = pipe.gets
        print line
        result << line
      end
    end
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
