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
    attr_reader :reader
    attr_reader :writer

    # Returns `true` if this `IO` is closed.
    #
    # Underlying `IO`s might have a different status.
    attr_reader :closed

    @closed = false

    WRITER_DELEGATE = %w[
      <<
    ].freeze

    READER_DELEGATE = %w[
      eof
      eof?
    ].freeze

    alias_method :sync_close?, :sync_close
    alias_method :closed?, :closed

    # Creates a new `IO::Stapled` which reads from *reader* and writes to *writer*.
    def initialize(reader, writer, sync_close: false)
      @reader = reader
      @writer = writer
      @sync_close = sync_close
    end

    def method_missing(name, *args, &block)
      if write_methods?(name.to_s)
        check_open
        @writer.send(name, *args, &block)
      elsif read_methods?(name.to_s)
        check_open
        @reader.send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      super || write_methods?(name.to_s) || read_methods?(name.to_s)
    end

    def write_methods?(name)
      name.include?("put") || name.include?("prin") ||
        name.include?("write") || WRITER_DELEGATE.include?(name)
    end

    def read_methods?(name)
      name.include?("get") || name.include?("read") ||
        name.include?("each") || READER_DELEGATE.include?(name)
    end

    # Flushes `writer`.
    def flush
      check_open

      @writer.flush

      self
    end

    def close_write
      @writer.close
    end

    def close_read
      @reader.close
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

    protected def check_open
      raise IOError.new("Closed stream") if closed?
    end
  end
end
