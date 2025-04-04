# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _comment_ tag.
  class BlockComment < Tag
    def self.parse(stream, _parser)
      # @type var children: Array[Token | Node]
      children = stream.eat_empty_tag("comment")
      token = stream.eat(:token_comment)
      children << token
      children.push(*stream.eat_empty_tag("endcomment"))
      new(children, token.text)
    end

    # @param children [Array<Token|Node>]
    # @param text [String]
    def initialize(children, text)
      super(children)
      @text = text
    end

    def render(_context, _buffer) = 0
  end
end
