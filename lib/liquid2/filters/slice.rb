# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return the subsequence of _left_ starting at _start_ up to _length_.
    def self.slice(left, start, length = 1)
      case left
      when Array
        left.slice(start, to_integer(length)) || []
      else
        Liquid2.to_s(left).slice(start, to_integer(length)) || ""
      end
    end
  end
end
