# frozen_string_literal: true

# This class staples together two unidirectional `IO`s to form a single,
# bidirectional `IO`.
#
# Example (loopback):
# ```
# io = IO::Stapled.new(*IO.pipe)
# io.puts "linus"
# io.gets # => "linus"
# ```
#
# Most methods simply delegate to the underlying `IO`s.
class IO
  class Stapled
    # If `#sync_close?` is `true`, closing this `IO` will close the underlying `IO`s.
    attr_accessor :sync_close

    # Returns `true` if this `IO` is closed.
    #
    # Underlying `IO`s might have a different status.
    attr_reader :closed

    @closed = false

    alias_method :sync_close?, :sync_close
    alias_method :closed?, :closed

    # Creates a new `IO::Stapled` which reads from *reader* and writes to *writer*.
    def initialize(reader, writer, sync_close: false)
      @reader = reader
      @writer = writer
      @sync_close = sync_close
    end

    def read(...)
      check_open

      @reader.read(...)
    end

    def readlines(...)
      check_open

      @reader.readlines(...)
    end

    def each_line(...)
      check_open

      @reader.each_line(...)
    end

    # Gets a string from `reader`.
    def gets(...)
      check_open

      @reader.gets(...)
    end

    def puts(...)
      check_open

      @writer.puts(...)
    end

    def print(...)
      check_open

      @writer.print(...)
    end

    def printf(...)
      check_open

      @writer.print(...)
    end

    def write(...)
      check_open

      @writer.write(...)
    end

    # Flushes `writer`.
    def flush
      check_open

      @writer.flush

      self
    end

    # Closes this `IO`.
    #
    # If `sync_close?` is `true`, it will also close the underlying `IO`s.
    def close
      return nil if @closed

      @closed = true

      if @sync_close
        @reader.close
        @writer.close
      end
    end

    def close_write
      @writer.close
    end

    def close_read
      @reader.close
    end

    protected def check_open
      raise IOError.new("Closed stream") if closed?
    end
  end
end
