# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # A negated expression.
  class LogicalNot < Expression
    # @param expr [Expression]
    def initialize(token, expr)
      super(token)
      @expr = expr
    end

    def evaluate(context)
      !Liquid2.truthy?(context, context.evaluate(@expr))
    end

    def children = [@expr]
  end

  # Logical conjunction.
  class LogicalAnd < Expression
    # @param left [Expression]
    # @param right [Expression]
    def initialize(token, left, right)
      super(token)
      @left = left
      @right = right
    end

    def evaluate(context)
      left = context.evaluate(@left)
      Liquid2.truthy?(context, left) ? context.evaluate(@right) : left
    end

    def children = [@left, @right]
  end

  # Logical disjunction.
  class LogicalOr < Expression
    # @param left [Expression]
    # @param right [Expression]
    def initialize(token, left, right)
      super(token)
      @left = left
      @right = right
    end

    def evaluate(context)
      left = context.evaluate(@left)
      Liquid2.truthy?(context, left) ? left : context.evaluate(@right)
    end

    def children = [@left, @right]
  end

  # A logical expression with explicit parentheses.
  class GroupedExpression < Expression
    # @param expr [Expression]
    def initialize(token, expr)
      super(token)
      @expr = expr
    end

    def evaluate(context)
      context.evaluate(@expr)
    end

    def children = [@expr]
  end
end
