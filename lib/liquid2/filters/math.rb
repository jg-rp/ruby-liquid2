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

    # Return the result of multiplying _left_ by _right_.
    def self.times(left, right)
      to_decimal(left) * to_decimal(right) # steep:ignore
    end

    # Return _left_ rounded down to the next whole number.
    def self.floor(left)
      to_number(left).floor
    end

    # Return _right_ subtracted from _left_.
    def self.minus(left, right)
      to_decimal(left) - to_decimal(right) # steep:ignore
    end

    # Return the remainder of dividing _left_ by _right_.
    def self.modulo(left, right)
      to_decimal(left) % to_decimal(right) # steep:ignore
    rescue ZeroDivisionError => e
      raise LiquidTypeError.new(e.message, nil)
    end

    # Return _right_ added to _left_.
    def self.plus(left, right)
      to_decimal(left) + to_decimal(right) # steep:ignore
    end

    # Return _left_ rounded to _ndigits_ decimal digits.
    def self.round(left, ndigits = 0)
      left = to_decimal(left)
      return left.round if ndigits == 0 # steep:ignore

      left.round(to_decimal(ndigits)) # steep:ignore
    end

    def self.sum(left, key = nil, context:)
      left = Liquid2::Filters.to_enumerable(left)

      case key
      when Liquid2::Lambda
        items = key.map(context, left).reject do |item|
          Liquid2.undefined?(item)
        end

        items.sum { |item| Liquid2::Filters.to_decimal(item) }
      when nil, Liquid2::Undefined
        left.sum { |item| Liquid2::Filters.to_decimal(item) } # steep:ignore
      else
        k = Liquid2.to_s(key)
        left.sum { |item| Liquid2::Filters.to_decimal(fetch(item, k)) } # steep:ignore
      end
    end
  end
end
