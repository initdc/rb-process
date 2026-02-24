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

    WRITER_DELEGATE = IO.instance_methods.grep(/^put|^print|write|<</).freeze
    READER_DELEGATE = IO.instance_methods.grep(/^get[a-z]*|read|each|eof/).freeze

    alias_method :sync_close?, :sync_close
    alias_method :closed?, :closed

    # Creates a new `IO::Stapled` which reads from *reader* and writes to *writer*.
    def initialize(reader, writer, sync_close: false)
      @closed = false
      @reader = reader
      @writer = writer
      @sync_close = sync_close
    end

    def method_missing(name, *args, &block)
      if WRITER_DELEGATE.include?(name)
        check_open
        @writer.send(name, *args, &block)
      elsif READER_DELEGATE.include?(name)
        check_open
        @reader.send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      WRITER_DELEGATE.include?(name) || READER_DELEGATE.include?(name) || super
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
