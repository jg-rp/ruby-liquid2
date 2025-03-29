# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class FilteredExpression < Expression
    def initialize(children, left, filters)
      super(children)
      @left = left
      @filters = filters
    end

    def evaluate(context)
      left = @left.evaluate(context)
      @filters.each { |f| left = f.evaluate(left, context) }
      left
    end
  end

  class TernaryExpression < Expression
    # @param children [Array<Token | Node>]
    # @param left [FilteredExpression]
    # @param condition [BooleanExpression]
    # @param alternative [Expression]
    # @param filters [Array<Filter>]
    # @param tail_filters [Array<Filter>]
    def initialize(children, left, condition, alternative, filters, tail_filters)
      super(children)
      @left = left
      @condition = condition
      @alternative = alternative
      @filters = filters
      @tail_filters = tail_filters
    end
  end

  class Filter < Node
    def initialize(children, name, args)
      super(children)
      @name = name.text
      @args = args
    end

    def evaluate(left, context)
      # TODO:
      func = context.env.filters[@name]
      func.call(left)
    end
  end
end
