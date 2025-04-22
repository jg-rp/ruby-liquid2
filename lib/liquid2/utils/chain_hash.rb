# frozen_string_literal: true

module Liquid2
  # Combine multiple hashes for sequential lookup.
  class ReadOnlyChainHash
    # @param hashes
    def initialize(*hashes)
      @hashes = hashes.to_a
    end

    def [](key)
      index = @hashes.length - 1
      while index >= 0
        h = @hashes[index]
        index -= 1
        return h[key] if h.key?(key)
      end
    end

    def key?(key)
      !@hashes.rindex { |h| h.key?(key) }.nil?
    end

    def fetch(key, default = :undefined)
      index = @hashes.length - 1
      while index >= 0
        h = @hashes[index]
        index -= 1
        return h[key] if h.key?(key)
      end

      default
    end

    def size = @hashes.length
    def push(hash) = @hashes << hash
    alias << push
    def pop = @hashes.pop
  end
end
