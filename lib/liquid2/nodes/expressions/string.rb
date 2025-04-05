# frozen_string_literal: true

require_relative "literals"
require_relative "../../node"

module Liquid2
  # Quoted string literal.
  class StringLiteral < Literal
    attr_reader :value

    # @param children [Array<Token, Expression>]
    # @param segments [Array<Expression>]
    def initialize(children, segments)
      token = children.first # : Token
      super(token)
      @children = children
      @segments = segments
      @value = segments.map(&:value).join
    end

    def evaluate(_context) = @value
  end

  # A literal part of a template string.
  class StringSegment < Expression
    attr_reader :value

    # @param token [Token]
    # @param quote ["'" | "/""]
    def initialize(token, quote)
      super([token])
      @value = Liquid2.unescape_string(token.text, quote, self)
    end

    def evaluate(_context) = @value
  end

  # Quoted string with interpolated expressions.
  class TemplateString < Expression
    # @param children [Array<Token, Expression>]
    # @param segments [Array<Expression>]
    def initialize(children, segments)
      super(children)
      @children = children
      @segments = segments
    end

    def evaluate(context)
      @segments.map { |expr| Liquid2.to_s(expr.evaluate(context)) }.join
    end
  end
end
