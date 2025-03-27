# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class Identifier < Expression
    # Try to cast _expr_ to an Identifier.
    # @param expr [Expression]
    def self.from(expr, trailing_question: true)
      # TODO:
      token = expr.children.first
      new([token], token)
    end

    # @param children [Array<Token>]
    # @param name [Token]
    def initialize(children, name)
      super(children)
      @name = name
    end
  end
end
