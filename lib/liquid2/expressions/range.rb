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
      from = Liquid2.to_liquid_int(context.evaluate(@start))
      to = Liquid2.to_liquid_int(context.evaluate(@stop))
      (from..to)
    end

    def to_s
      "(#{@start}..#{@stop})"
    end

    def children = [@start, @stop]
  end
end
