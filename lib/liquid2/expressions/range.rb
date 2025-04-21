# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # A range expression.
  class RangeExpression < Expression
    # @param start [Expression]
    # @param stop [Expression]
    def initialize(token, start, stop)
      super(token)
      @start = start
      @stop = stop
    end

    def evaluate(context)
      (Liquid2.to_liquid_int(context.evaluate(@start))..Liquid2.to_liquid_int(context.evaluate(@stop)))
    end
  end
end
