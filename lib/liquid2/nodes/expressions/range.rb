# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # A range expression.
  class RangeExpression < Expression
    # @param children [Array<Token, Node>]
    # @param start [Expression]
    # @param stop [Expression]
    def initialize(children, start, stop)
      super(children)
      @start = start
      @stop = stop
    end

    def evaluate(context)
      start = Liquid2.to_liquid_int(@start.evaluate(context))
      stop = Liquid2.to_liquid_int(@start.evaluate(context))
      (start..stop)
    end
  end
end
