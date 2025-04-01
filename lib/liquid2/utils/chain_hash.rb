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
        return hash.fetch(key) if hash.key?(key) # TODO: this causes two scope traversals
      end
      nil
    end

    def size
      @hashes.length
    end

    def key?(key)
      @hashes.reverse_each do |hash|
        return true if hash.key?(key)
      end
      false
    end

    def fetch(key, default = :undefined)
      @hashes.reverse_each do |hash|
        return hash.fetch(key) if hash.key?(key) # TODO: this causes two scope traversals
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
