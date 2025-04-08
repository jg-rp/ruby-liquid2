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

    # Return _left_ rounded up to the next whole number.
    def self.ceil(left)
      to_number(left).ceil
    end

    # Return the result of dividing _left_ by _right_.
    # If both _left_ and _right_ are integers, integer division is performed.
    def self.divided_by(left, right)
      to_decimal(left) / to_decimal(right) # steep:ignore
    rescue ZeroDivisionError => e
      raise LiquidTypeError.new(e.message, nil)
    end
  end
end
