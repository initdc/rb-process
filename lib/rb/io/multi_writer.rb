# frozen_string_literal: true

# An `IO` which writes to a number of underlying writer IOs.
#
# ```
# io1 = IO::Memory.new
# io2 = IO::Memory.new
# writer = IO::MultiWriter.new(io1, io2)
# writer.puts "foo bar"
# io1.to_s # => "foo bar\n"
# io2.to_s # => "foo bar\n"
# ```
class IO
  class MultiWriter
    # If `#sync_close?` is `true`, closing this `IO` will close all of the underlying
    # IOs.
    attr_accessor :sync_close
    attr_reader :closed

    @closed = false

    alias_method :sync_close?, :sync_close
    alias_method :closed?, :closed

    def initialize(*writers, sync_close: false)
      @writers = writers
      @sync_close = sync_close
    end

    def write(slice)
      check_open

      return nil if slice.empty?

      @writers.each { |w| w.write(slice) }
    end

    def read(_slice)
      raise IO::Error, "Can't read from IO::MultiWriter"
    end

    def close
      return nil if @closed

      @closed = true

      @writers.each(&:close) if sync_close?
    end

    def flush
      @writers.each(&:flush)
    end

    protected def check_open
      raise IOError.new("Closed stream") if closed?
    end
  end
end
