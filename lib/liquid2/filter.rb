# frozen_string_literal: true

require "bigdecimal"
require "time"

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Cast _obj_ to an enumerable for use in a Liquid filter.
    # @param obj [Object]
    # @return [Enumerable]
    def self.to_enumerable(obj)
      case obj
      when Array
        obj.flatten
      when Hash, String
        [obj]
      # when String
      #   obj.each_char
      when Enumerable
        obj
      else
        obj.respond_to?(:each) ? obj.each : [obj]
      end
    end

    # Cast _obj_ to a number.
    def self.to_number(obj, default: 0)
      case obj
      when String
        # Cast to float before integer as `to_f` will parse exponents, `to_i` will not.
        # Use `Float(obj)` instead of `obj.to_f` because `to_f` ignores trailing non-digit chars.
        obj.match?(/\A-?\d+(?:[eE]\+?\d+)?\Z/) ? obj.to_f.to_i : Float(obj)
      when Float, Integer, BigDecimal, Numeric
        # Numeric is the base class for heap allocated numbers.
        obj
      else
        default
      end
    rescue ArgumentError
      default
    end

    # Case _obj_ to an Integer.
    def self.to_integer(obj)
      obj.is_a?(Integer) ? obj : Integer(obj)
    end

    # Cast _obj_ to a number, favouring BigDecimal over Float.
    def self.to_decimal(obj, default: 0)
      case obj
      when String
        obj.match?(/\A-?\d+(?:[eE]\+?\d+)?\Z/) ? obj.to_f.to_i : BigDecimal(obj)
      when Float
        BigDecimal(obj.to_s)
      when Integer, BigDecimal, Numeric
        obj
      else
        default
      end
    rescue ArgumentError
      default
    end

    # Cast _obj_ to a  date and time. Return `nil` if casting fails.
    # NOTE: This was copied from Shopify/liquid.
    def self.to_date(obj)
      return obj if obj.respond_to?(:strftime)

      if obj.is_a?(String)
        return nil if obj.empty?

        obj = obj.downcase
      end

      case obj
      when "now", "today"
        Time.now
      when /\A\d+\z/, Integer
        Time.at(obj.to_i)
      when String
        Time.parse(obj)
      end
    rescue ::ArgumentError
      nil
    end

    def self.fetch(obj, key, default = nil)
      obj[key]
    rescue ArgumentError, TypeError, NoMethodError
      default
    end
  end
end
