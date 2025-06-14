# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # The special value _blank_.
  class Blank < Expression
    def evaluate(_context)
      self
    end

    def ==(other)
      return true if other.is_a?(String) && (other.empty? || other.match?(/\A\s+\Z/))

      return other.empty? if other.respond_to?(:empty?)

      other.is_a?(Blank)
    end

    alias eql? ==

    def to_s = ""
  end

  # The special value _empty_.
  class Empty < Expression
    def evaluate(_context)
      self
    end

    def ==(other)
      return other.empty? if other.respond_to?(:empty?)

      other.is_a?(Empty)
    end

    alias eql? ==

    def to_s = ""
  end
end
