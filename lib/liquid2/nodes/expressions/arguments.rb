# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class PositionalArgument < Expression
    def initialize(children, value)
      super(children)
      @value = value
    end
  end

  class KeywordArgument < Expression
    def initialize(children, name, value)
      super(children)
      @name = name
      @value = value
    end
  end
end
