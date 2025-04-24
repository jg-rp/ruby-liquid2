# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _capture_ tag.
  class CaptureTag < Tag
    END_BLOCK = Set["endcapture"]

    # @param parser [Parser]
    # @return [CaptureTag]
    def self.parse(token, parser)
      name = parser.parse_identifier(trailing_question: false)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      block = parser.parse_block(END_BLOCK)
      parser.eat_empty_tag("endcapture")
      new(token, name, block)
    end

    # @param name [Identifier]
    # @param block [Block]
    def initialize(token, name, block)
      super(token)
      @name = name
      @block = block
      @block.blank = false
      @blank = false
    end

    def render(context, _buffer)
      buf = +""
      @block.render(context, buf)
      context.assign(@name.name, buf)
    end

    def children(_static_context, include_partials: true) = [@block]
    def template_scope = [@name]
  end
end
