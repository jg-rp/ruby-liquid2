# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class LogicalNot < Expression
    # @param children [Array<Token, Node>]
    # @param expr [Expression]
    def initialize(children, expr)
      super(children)
      @expr = expr
    end

    def evaluate(context)
      !Liquid2.truthy?(@expr.evaluate(context))
    end
  end

  class LogicalAnd < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end

    def evaluate(context)
      left = @left.evaluate(context)
      Liquid2.truthy?(left) ? @right.evaluate(context) : left
    end
  end

  class LogicalOr < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end

    def evaluate(context)
      left = @left.evaluate(context)
      Liquid2.truthy?(left) ? left : @right.evaluate(context)
    end
  end

  # A logical expression with explicit parentheses.
  class GroupedExpression < Expression
    # @param children [Array<Token, Node>]
    # @param expr [Expression]
    def initialize(children, expr)
      super(children)
      @expr = expr
    end

    def evaluate(context)
      @expr.evaluate(context)
    end
  end
end
