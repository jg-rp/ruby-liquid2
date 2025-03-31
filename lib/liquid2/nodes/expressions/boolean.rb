# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class BooleanExpression < Expression
    # @param expr [Expression]
    def initialize(expr)
      super([expr])
      @expr = expr
    end

    def evaluate(context)
      Liquid2.truthy?(context, @expr.evaluate(context))
    end
  end
end
