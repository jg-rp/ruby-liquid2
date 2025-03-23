# frozen_string_literal: true

require_relative "../ast"

module Liquid2
  # The AST node representing output statements.
  class Output < Node
    attr_reader :expression

    # @param tokens [Array<Token>]
    # @param children [Array<Node>]
    # @param expression [Expression]
    def initialize(tokens, children, expression)
      super(tokens, children)
      @expression = expression
      @blank = false
    end

    def render(context, buffer)
      buffer.write(Liquid2.to_liquid_string(@expression.evaluate(context),
                                            auto_escape: context.auto_escape))
    end
  end
end
