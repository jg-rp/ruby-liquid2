# frozen_string_literal: true

require_relative "blank"
require_relative "../expression"

module Liquid2 # :nodoc:
  # Base class for all arithmetic expressions.
  class ArithmeticExpression < Expression
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
      [Liquid2::Filters.to_decimal(left), Liquid2::Filters.to_decimal(right)]
    end
  end

  # Infix addition
  class Plus < ArithmeticExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      left + right
    end
  end

  # Infix subtraction
  class Minus < ArithmeticExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      left - right
    end
  end

  # Infix multiplication
  class Times < ArithmeticExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      left * right
    end
  end

  # Infix division
  class Divide < ArithmeticExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      left / right
    rescue ZeroDivisionError => e
      raise LiquidTypeError.new(e.message, nil)
    end
  end

  # Infix modulo
  class Modulo < ArithmeticExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      left % right
    rescue ZeroDivisionError => e
      raise LiquidTypeError.new(e.message, nil)
    end
  end

  # Infix exponentiation
  class Pow < ArithmeticExpression
    def evaluate(context)
      left, right = inner_evaluate(context)
      left**right
    end
  end

  # Prefix negation
  class Negative < Expression
    # @param right [Expression]
    def initialize(token, right)
      super(token)
      @right = right
    end

    def evaluate(context)
      right = context.evaluate(@right)
      value = Liquid2::Filters.to_decimal(right, default: nil)
      if value.respond_to?(:-@)
        value.send(:-@)
      else
        context.env.undefined("-(#{Liquid2.to_output_string(right.inspect)})", node: self)
      end
    end

    def children = [@right]
  end

  # Prefix positive
  class Positive < Expression
    # @param right [Expression]
    def initialize(token, right)
      super(token)
      @right = right
    end

    def evaluate(context)
      right = context.evaluate(@right)
      value = Liquid2::Filters.to_decimal(right, default: nil)
      if value.respond_to?(:+@)
        value.send(:+@)
      else
        context.env.undefined("+(#{Liquid2.to_output_string(right.inspect)})", node: self)
      end
    end

    def children = [@right]
  end
end
