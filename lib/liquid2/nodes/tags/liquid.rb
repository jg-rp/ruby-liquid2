# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _liquid_ tag.
  class LiquidTag < Node
    # @param stream [TokenStream]
    # @param parser [Parser]
    # @return [LiquidTag]
    def self.parse(stream, parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      block = parser.parse_line_statements(stream)
      children << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      new(children, block)
    end

    def initialize(children, block)
      super(children)
      @block = block
      @blank = block.blank
    end

    def render(context, buffer)
      @block.render(context, buffer)
    end
  end
end
