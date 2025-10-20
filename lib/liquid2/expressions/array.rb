# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # An array literal.
  class ArrayLiteral < Expression
    # @param token [[Symbol, String?, Integer]]
    # @param items [Array<Expression>]
    def initialize(token, items)
      super(token)
      @items = items
    end

    # @param context [RenderContext]
    # @return [untyped]
    def evaluate(context)
      result = [] # : Array[untyped]
      @items.each do |item|
        value = context.evaluate(item)
        if item.is_a?(ArraySpread)
          case value
          when Array
            result.concat(value)
          when Hash, String
            result << value
          when Enumerable
            result.concat(value.to_a)
          else
            if value.respond_to?(:each)
              result.concat(value.each)
            else
              result << value
            end
          end
        else
          result << value
        end
      end
      result
    end

    def children = @items
  end

  # Represents a spread element inside an array literal, e.g. ...expr
  class ArraySpread < Expression
    # @param token [[Symbol, String?, Integer]]
    # @param expr [Expression]
    def initialize(token, expr)
      super(token)
      @expr = expr
    end

    def evaluate(context) = context.evaluate(@expr)

    def children = [@expr]
  end
end
