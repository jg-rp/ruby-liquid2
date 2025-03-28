# frozen_string_literal: true

module Liquid2
  # Combine multiple hashes for sequential lookup.
  class ReadOnlyChainHash
    # @param hashes
    def initialize(*hashes)
      @hashes = hashes.to_a
    end

    def [](key)
      @hashes.reverse_each do |hash|
        return hash[key] if hash.key?(key)
      end
      nil
    end

    def size
      @hashes.length
    end

    def fetch(key, default: :undefined)
      @hashes.reverse_each do |hash|
        return hash[key] if hash.key?(key)
      end
      default
    end

    def push(hash)
      @hashes << hash
    end

    alias << push

    def pop
      @hashes.pop
    end
  end
end
