# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _raw_ tag.
  class RawTag < Node
    # @param stream [TokenStream]
    # @param parser [Parser]
    # @return [RawTag]
    def self.parse(stream, _parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name),
                  stream.eat(:token_tag_end)]

      raw = stream.eat(:token_raw)
      children << raw
      children.push(*stream.eat_empty_tag("endraw"))
      new(children, raw.text)
    end

    # @param children [Array<Token | Node>]
    # @param text [String]
    def initialize(children, text)
      super(children)
      @text = text
      @blank = false
    end

    def render(_context, buffer)
      buffer.write(@text)
    end
  end
end
