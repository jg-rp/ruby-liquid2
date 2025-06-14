# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # An expression that evaluates to true or false.
  class BooleanExpression < Expression
    # @param expr [Expression]
    def initialize(token, expr)
      super(token)
      @expr = expr
    end

    def evaluate(context)
      value = context.evaluate(@expr)
      Liquid2.truthy?(context, value.respond_to?(:to_liquid) ? value.to_liquid(context) : value)
    end

    def children = [@expr]
  end
end
