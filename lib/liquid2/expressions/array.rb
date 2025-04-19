# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # An array literal.
  class ArrayLiteral < Expression
    # @param items [Array<Expression>]
    def initialize(token, items)
      super(token)
      @items = items
    end

    def evaluate(context)
      @items.map { |item| context.evaluate(item) }
    end
  end
end
