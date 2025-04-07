# frozen_string_literal: true

require_relative "../node"

module Liquid2
  # The AST node representing output statements.
  class Output < Node
    attr_reader :expression, :wc

    # @param children [Array<Node | Token>]
    # @param expression [Expression]
    def initialize(children, expression)
      super(children)
      @expression = expression
      @blank = false
      @wc = @children.map do |child|
        WC_MAP.fetch(child.text) if child.is_a?(Token) && child.kind == :token_whitespace_control
      end.compact
    end

    def render(context, buffer)
      buffer.write(Liquid2.to_output_s(@expression.evaluate(context)))
    end
  end
end
