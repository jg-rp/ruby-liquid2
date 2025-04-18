# frozen_string_literal: true

require_relative "../node"

module Liquid2
  # The AST node representing output statements.
  class Output < Node
    attr_reader :expression

    # @param token [[Symbol, String?, Integer]]
    # @param expression [Expression]
    def initialize(token, expression)
      super(token)
      @expression = expression
      @blank = false
    end

    def render(context, buffer)
      buffer.write(Liquid2.to_output_s(@expression.evaluate(context)))
    end
  end
end
