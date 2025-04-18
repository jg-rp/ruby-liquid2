# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  class PositionalArgument < Expression
    attr_reader :value

    # @param value [Expression]
    def initialize(token, value)
      super(token)
      @value = value
    end

    def evaluate(context)
      [nil, context.evaluate(@value)]
    end
  end

  class KeywordArgument < Expression
    attr_reader :value, :name

    # @param name [String]
    # @param value [Expression]
    def initialize(token, name, value)
      super(token)
      @name = name
      @value = value
    end

    def evaluate(context)
      [@name, context.evaluate(@value)]
    end
  end
end
