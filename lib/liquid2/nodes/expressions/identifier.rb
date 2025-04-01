# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class Identifier < Expression
    attr_reader :name

    # Try to cast _expr_ to an Identifier.
    # @param expr [Expression]
    def self.from(expr, trailing_question: true)
      # TODO:
      token = expr.children.first
      new(token)
    end

    # @param name [Token]
    def initialize(name)
      super([name])
      # TODO: make identifier behave like a string?
      @name = name.text
    end

    def evaluate(_context)
      @name
    end
  end
end
