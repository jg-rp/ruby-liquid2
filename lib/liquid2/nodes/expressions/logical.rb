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
  end

  # A logical expression with explicit parentheses.
  class LogicalGroup < Expression
    # @param children [Array<Token, Node>]
    # @param expr [Expression]
    def initialize(children, expr)
      super(children)
      @expr = expr
    end
  end
end
