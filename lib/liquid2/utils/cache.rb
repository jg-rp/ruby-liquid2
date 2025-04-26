# frozen_string_literal: true

require "monitor"

module Liquid2
  # A least recently used cache relying on Ruby hash insertion order.
  class LRUCache
    attr_reader :max_size

    def initialize(max_size = 128)
      @data = {}
      @max_size = max_size
    end

    # Return the cached value or nil if _key_ does not exist.
    def [](key)
      val = @data[key]
      return nil if val.nil?

      @data.delete(key)
      @data[key] = val
      val
    end

    def []=(key, value)
      if @data.key?(key)
        @data.delete(key)
      elsif @data.length >= @max_size
        @data.delete((@data.first || raise)[0])
      end
      @data[key] = value
    end

    def length
      @data.length
    end

    def keys
      @data.keys
    end
  end

  # A thread safe least recently used cache.
  class ThreadSafeLRUCache < LRUCache
    include MonitorMixin

    alias unsafe_get []
    alias unsafe_set []=
    alias unsafe_length length
    alias unsafe_keys keys

    def initialize(max_size = 128)
      super
    end

    def [](key)
      synchronize do
        unsafe_get(key)
      end
    end

    def []=(key, value)
      synchronize do
        unsafe_set(key, value)
      end
    end

    def length
      synchronize do
        unsafe_length
      end
    end

    def keys
      synchronize do
        unsafe_keys
      end
    end
  end
end
