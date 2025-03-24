# frozen_string_literal: true

require_relative "../node"

module Liquid2
  # The AST node representing output statements.
  class Output < Node
    attr_reader :expression

    # @param children [Array<Node | Token>]
    # @param expression [Expression]
    def initialize(children, expression)
      # Whitespace control is guaranteed to be at children[1] and children[-2]
      super(children)
      @expression = expression
      @blank = false
    end

    def render(context, buffer)
      buffer.write(Liquid2.to_liquid_string(@expression.evaluate(context),
                                            auto_escape: context.auto_escape))
    end
  end
end
