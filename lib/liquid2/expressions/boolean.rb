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
      Liquid2.truthy?(context, context.evaluate(@expr))
    end
  end
end
