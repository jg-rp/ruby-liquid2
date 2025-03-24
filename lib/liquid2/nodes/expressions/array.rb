# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # An array literal.
  class ImplicitArray < Expression
    # @param children [Array<Token, Node>]
    # @param items [Array<Expression>]
    def initialize(children, items)
      super(children)
      @items = items
    end

    def evaluate(context)
      @items.map { |item| item.evaluate(context) }
    end
  end
end
