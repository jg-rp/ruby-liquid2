# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _capture_ tag.
  class CaptureTag < Tag
    END_BLOCK = Set["endcapture"]

    # @param stream [TokenStream]
    # @param parser [Parser]
    # @return [CaptureTag]
    def self.parse(stream, parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      name = parser.parse_identifier(stream, trailing_question: false)
      children << name << stream.eat(:token_assign)
      block = parser.parse_block(stream, END_BLOCK)
      children << block
      children.push(*stream.eat_empty_tag("endcapture"))
      new(children, name, block)
    end

    # @param children [Array<Token | Node>]
    # @param name [Identifier]
    # @param block [Block]
    def initialize(children, name, block)
      super(children)
      @name = name.name
      @block = block
    end

    def render(context, buffer)
      buf = context.get_output_buffer(buffer)
      @block.render(context, buf)
      context.assign(@name, buf.string)
      0
    end
  end
end
