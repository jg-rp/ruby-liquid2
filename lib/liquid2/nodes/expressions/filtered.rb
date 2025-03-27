# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class FilteredExpression < Expression
    def initialize(children, left, filters)
      super(children)
      @left = left
      @filters = filters
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

  class Filter < Expression
    def initialize(children, name, args)
      super(children)
      @name = name
      @args = args
    end
  end
end
