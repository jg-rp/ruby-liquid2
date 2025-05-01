# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # A keyword argument with a name and a value.
  class KeywordArgument < Expression
    attr_reader :value, :name, :sym

    # @param name [String]
    # @param value [Expression]
    def initialize(token, name, value)
      super(token)
      @name = name
      @sym = name.to_sym
      @value = value
    end

    def evaluate(context)
      [@name, context.evaluate(@value)]
    end

    def children = [@value]
  end
end
