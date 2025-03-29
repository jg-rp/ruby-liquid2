# frozen_string_literal: true

require "stringio"

module Liquid2
  # A StringIO subclass that raises an exception when the buffer reaches a limit.
  class LimitedStringIO < StringIO
    def initialize(limit, ...)
      super(...)
      @limit = limit
    end

    def write(...)
      byte_count = super
      raise "output limit reached" if @length > @limit

      byte_count
    end
  end

  # A StringIO subclass with a _write_ method that is a no op.
  class NullIO < StringIO
    def write(...) = 0
  end
end
