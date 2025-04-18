# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _decrement_ tag.
  class DecrementTag < Node
    # @param stream [TokenStream]
    # @param parser [Parser]
    # @return [DecrementTag]
    def self.parse(stream, parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      name = parser.parse_identifier(stream, trailing_question: false)
      children << name << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      new(children, name)
    end

    # @param children [Array<Token | Node>]
    # @param name [Identifier]
    def initialize(children, name)
      super(children)
      @name = name.name
    end

    def render(context, buffer)
      buffer.write(context.decrement(@name).to_s)
    end
  end
end
