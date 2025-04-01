# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _for_ tag.
  class ForTag < Node
    def self.parse(stream, parser)
      # TODO:
    end

    # @param children [Array<Token|Node>]
    # @param expression [LoopExpression]
    # @param block [Block]
    # @param default [Block?]
    def initialize(children, expression, block, default)
      super(children)
      @expression = expression
      @block = block
      @default = default
    end

    def render(context, buffer)
      # TODO:
    end
  end
end
