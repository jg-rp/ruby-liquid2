# frozen_string_literal: true

require_relative "blank"
require_relative "../expression"

module Liquid2
  # Base for comparison expressions.
  class ComparisonExpression < Expression
    # @param left [Expression]
    # @param right [Expression]
    def initialize(token, left, right)
      super(token)
      @left = left
      @right = right
    end

    protected

    def inner_evaluate(context)
      left = @left.evaluate(context)
      right = @right.evaluate(context)
      left = left.to_liquid(context) if left.respond_to?(:to_liquid)
      right = right.to_liquid(context) if right.respond_to?(:to_liquid)
      [left, right]
    end
  end

  class Eq < ComparisonExpression
    def evaluate(context)
      Liquid2.eq(*inner_evaluate(context))
    end
  end

  class Ne < ComparisonExpression
    def evaluate(context)
      !Liquid2.eq(*inner_evaluate(context))
    end
  end

  class Le < ComparisonExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      Liquid2.eq(left, right) || Liquid2.lt(left, right)
    end
  end

  class Ge < ComparisonExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      Liquid2.eq(left, right) || Liquid2.lt(right, left)
    end
  end

  class Lt < ComparisonExpression
    def evaluate(context)
      Liquid2.lt(*inner_evaluate(context))
    end
  end

  class Gt < ComparisonExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      Liquid2.lt(right, left)
    end
  end

  class Contains < ComparisonExpression
    def evaluate(context)
      left = @left.evaluate(context)
      right = @right.evaluate(context)
      Liquid2.contains(left, right)
    end
  end

  # TODO: pass or inject a Token into errors
  # TODO: move these to liquid2.rb?
  # TODO: rename these with trailing "?"

  # Test _left_ and _right_ for Liquid equality.
  def self.eq(left, right)
    left, right = right, left if right.is_a?(Empty) || right.is_a?(Blank)
    left == right
  rescue ::ArgumentError => e
    raise Liquid2::LiquidArgumentError, e.message
  end

  # Return `true` if _left_ is considered less than _right_.
  def self.lt(left, right)
    left < right
  rescue ::ArgumentError => e
    raise Liquid2::LiquidArgumentError, e.message
  end

  def self.contains(left, right)
    return false unless left.respond_to?(:include?)

    right = Liquid2.to_s(right) if left.is_a?(String)
    left.include?(right)
  rescue ::ArgumentError => e
    raise Liquid2::LiquidArgumentError, e.message
  end
end
