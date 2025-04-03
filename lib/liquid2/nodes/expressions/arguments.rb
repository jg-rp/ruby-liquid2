# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class PositionalArgument < Expression
    attr_reader :value

    # @param children [Array<Token | Node>]
    # @param value [Expression]
    def initialize(children, value)
      super(children)
      @value = value
    end

    def evaluate(context)
      [nil, @value.evaluate(context)]
    end
  end

  class KeywordArgument < Expression
    # @param children [Array<Token | Node>]
    # @param name [Token]
    # @param value [Expression]
    def initialize(children, name, value)
      super(children)
      @name = name.text
      @value = value
    end

    def evaluate(context)
      [@name, @value.evaluate(context)]
    end
  end
end
