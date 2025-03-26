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

  class Filter < Expression
    def initialize(children, name, args)
      super(children)
      @name = name
      @args = args
    end
  end
end
