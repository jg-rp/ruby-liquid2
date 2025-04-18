# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  class LogicalNot < Expression
    # @param expr [Expression]
    def initialize(token, expr)
      super(token)
      @expr = expr
    end

    def evaluate(context)
      !Liquid2.truthy?(context, @expr.evaluate(context))
    end
  end

  class LogicalAnd < Expression
    # @param left [Expression]
    # @param right [Expression]
    def initialize(token, left, right)
      super(token)
      @left = left
      @right = right
    end

    def evaluate(context)
      left = @left.evaluate(context)
      Liquid2.truthy?(context, left) ? @right.evaluate(context) : left
    end
  end

  class LogicalOr < Expression
    # @param left [Expression]
    # @param right [Expression]
    def initialize(token, left, right)
      super(token)
      @left = left
      @right = right
    end

    def evaluate(context)
      left = @left.evaluate(context)
      Liquid2.truthy?(context, left) ? left : @right.evaluate(context)
    end
  end

  # A logical expression with explicit parentheses.
  class GroupedExpression < Expression
    # @param expr [Expression]
    def initialize(token, expr)
      super(token)
      @expr = expr
    end

    def evaluate(context)
      @expr.evaluate(context)
    end
  end
end
