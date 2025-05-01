# frozen_string_literal: true

require_relative "blank"
require_relative "../expression"

module Liquid2 # :nodoc:
  # Base for comparison expressions.
  class ComparisonExpression < Expression
    # @param left [Expression]
    # @param right [Expression]
    def initialize(token, left, right)
      super(token)
      @left = left
      @right = right
    end

    def children = [@left, @right]

    protected

    def inner_evaluate(context)
      left = context.evaluate(@left)
      right = context.evaluate(@right)
      left = left.to_liquid(context) if left.respond_to?(:to_liquid)
      right = right.to_liquid(context) if right.respond_to?(:to_liquid)
      [left, right]
    end
  end

  # Infix ==
  class Eq < ComparisonExpression
    def evaluate(context)
      Liquid2.eq?(*inner_evaluate(context))
    end
  end

  # Infix != or <>
  class Ne < ComparisonExpression
    def evaluate(context)
      !Liquid2.eq?(*inner_evaluate(context))
    end
  end

  # Infix <=
  class Le < ComparisonExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      Liquid2.eq?(left, right) || Liquid2.lt?(left, right)
    end
  end

  # Infix >=
  class Ge < ComparisonExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      Liquid2.eq?(left, right) || Liquid2.lt?(right, left)
    end
  end

  # Infix <
  class Lt < ComparisonExpression
    def evaluate(context)
      Liquid2.lt?(*inner_evaluate(context))
    end
  end

  # Infix >
  class Gt < ComparisonExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      Liquid2.lt?(right, left)
    end
  end

  # Infix `contains`
  class Contains < ComparisonExpression
    def evaluate(context)
      left = context.evaluate(@left)
      right = context.evaluate(@right)
      Liquid2.contains?(left, right)
    end
  end

  # Infix `in`
  class In < ComparisonExpression
    def evaluate(context)
      left = context.evaluate(@left)
      right = context.evaluate(@right)
      Liquid2.contains?(right, left)
    end
  end

  # Test _left_ and _right_ for Liquid equality.
  def self.eq?(left, right)
    left, right = right, left if right.is_a?(Empty) || right.is_a?(Blank)
    left == right
  rescue ::ArgumentError => e
    raise Liquid2::LiquidArgumentError, e.message
  end

  # Return `true` if _left_ is considered less than _right_.
  def self.lt?(left, right)
    left < right
  rescue ::ArgumentError => e
    raise Liquid2::LiquidArgumentError, e.message
  end

  def self.contains?(left, right)
    return false unless left.respond_to?(:include?)

    if left.is_a?(String)
      right.nil? || Liquid2.undefined?(right) ? false : left.include?(Liquid2.to_s(right))
    else
      left.include?(right)
    end
  rescue ::ArgumentError => e
    raise Liquid2::LiquidArgumentError, e.message
  end
end
