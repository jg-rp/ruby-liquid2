# frozen_string_literal: true

require_relative "literals"
require_relative "../../node"

module Liquid2
  # Quoted string literal.
  class StringLiteral < Literal
    # @param children [Array<Token, Expression>]
    def initialize(children)
      super(children.first)
      @children = children
      @value = children[1].value
    end

    def evaluate(_context) = @value
  end

  # Quoted string with interpolated expressions.
  class TemplateString < Expression
    # @param children [Array<Token, Expression>]
    # @param segments [Array<Expression>]
    def initialize(children, segments)
      super(children.first)
      @children = children
      @segments = segments
    end

    def evaluate(context)
      @segments.map { |expr| Liquid2.to_liquid_string(expr.evaluate(context)) }.join
    end
  end
end
