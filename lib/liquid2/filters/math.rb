# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return the absolute value of _left_.
    def self.abs(left)
      to_number(left).abs
    end

    # Return the maximum of _left_ and _right_.
    def self.at_least(left, right)
      [to_number(left), to_number(right)].max
    end

    # Return the minimum of _left_ and _right_.
    def self.at_most(left, right)
      [to_number(left), to_number(right)].min
    end
  end
end
