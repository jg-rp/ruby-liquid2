# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _liquid_ tag.
  class LiquidTag < Node
    # @param parser [Parser]
    # @return [LiquidTag]
    def self.parse(token, parser)
      block = parser.parse_line_statements
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, block)
    end

    def initialize(token, block)
      super(token)
      @block = block
      @blank = block.blank
    end

    def render(context, buffer)
      @block.render(context, buffer)
    end
  end
end
