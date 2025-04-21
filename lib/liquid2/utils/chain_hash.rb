# frozen_string_literal: true

module Liquid2
  # Combine multiple hashes for sequential lookup.
  class ReadOnlyChainHash
    # @param hashes
    def initialize(*hashes)
      @hashes = hashes.to_a
    end

    def [](key)
      if (index = @hashes.rindex { |h| h.key?(key) })
        @hashes[index][key]
      end
    end

    def key?(key)
      !@hashes.rindex { |h| h.key?(key) }.nil?
    end

    def fetch(key, default = :undefined)
      if (index = @hashes.rindex { |h| h.key?(key) })
        @hashes[index][key]
      else
        default
      end
    end

    def size = @hashes.length
    def push(hash) = @hashes << hash
    alias << push
    def pop = @hashes.pop
  end
end
