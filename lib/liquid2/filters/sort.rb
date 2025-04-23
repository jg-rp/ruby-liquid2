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

    # XXX: copied from Shopify/liquid
    def self.nil_safe_compare(a, b)
      result = a <=> b

      if result
        result
      elsif a.nil?
        1
      elsif b.nil?
        -1
      else
        raise Liquid2::LiquidArgumentError.new("can't sort incomparable type", nil)
      end
    end

    # XXX: copied from Shopify/liquid
    def self.nil_safe_casecmp(a, b)
      if !a.nil? && !b.nil?
        a.to_s.casecmp(b.to_s)
      elsif a.nil? && b.nil?
        0
      else
        a.nil? ? 1 : -1
      end
    end
  end
end
