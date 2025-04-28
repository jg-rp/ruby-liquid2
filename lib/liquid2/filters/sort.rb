# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    def self.sort(left, key = nil, context:)
      left = Liquid2::Filters.to_enumerable(left)

      case key
      when Liquid2::Lambda
        key.map(context, left).zip(left).sort do |a, b|
          nil_safe_compare(a.first, b.first)
        end.map(&:last)
      when nil, Liquid2::Undefined
        left.sort { |a, b| nil_safe_compare(a, b) }
      else
        key = Liquid2.to_s(key)
        left.sort { |a, b| nil_safe_compare(fetch(a, key), fetch(b, key)) }
      end
    end

    def self.sort_natural(left, key = nil, context:)
      left = Liquid2::Filters.to_enumerable(left)

      case key
      when Liquid2::Lambda
        key.map(context, left).zip(left).sort do |a, b|
          nil_safe_casecmp(a.first, b.first)
        end.map(&:last)
      when nil, Liquid2::Undefined
        left.sort { |a, b| nil_safe_casecmp(a, b) }
      else
        key = Liquid2.to_s(key)
        left.sort { |a, b| nil_safe_casecmp(fetch(a, key), fetch(b, key)) }
      end
    end

    def self.sort_numeric(left, key = nil, context:)
      left = Liquid2::Filters.to_enumerable(left)

      case key
      when Liquid2::Lambda
        key.map(context, left).zip(left).sort do |a, b|
          numeric_compare(a.first, b.first)
        end.map(&:last)
      when nil, Liquid2::Undefined
        left.sort { |a, b| numeric_compare(a, b) }
      else
        key = Liquid2.to_s(key)
        left.sort { |a, b| numeric_compare(fetch(a, key), fetch(b, key)) }
      end
    end

    def self.nil_safe_compare(left, right)
      result = left <=> right

      if result
        result
      elsif left.nil?
        1
      elsif right.nil?
        -1
      else
        raise Liquid2::LiquidArgumentError.new("can't sort incomparable type", nil)
      end
    end

    def self.nil_safe_casecmp(left, right)
      if !left.nil? && !right.nil?
        left.to_s.casecmp(right.to_s)
      elsif left.nil? && right.nil?
        0
      else
        left.nil? ? 1 : -1
      end
    end

    def self.numeric_compare(left, right)
      # @type var res: untyped
      res = ints(left) <=> ints(right)
      res || -1
    end

    def self.ints(obj)
      case obj
      when Integer, Float, BigDecimal
        [obj]
      else
        numeric = obj.to_s.scan(/-?\d+/)
        return [Float::INFINITY] if numeric.empty?

        numeric.map(&:to_i)
      end
    end
  end
end
