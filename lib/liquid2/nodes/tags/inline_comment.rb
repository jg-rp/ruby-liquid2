# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # `{% # comment %}` style comments.
  class InlineComment < Node
    def self.parse(stream, _parser)
      children = [
        stream.eat(:token_tag_start),
        stream.eat_whitespace_control,
        stream.eat(:tag_name)
      ]

      token = stream.eat(:token_comment)
      children << token << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      new(children, token.text)
    end

    # @param children [Array<Node | Token>]
    # @param text [String]
    def initialize(children, text)
      super(children)
      @text = text
    end

    def render(_context, _buffer) = 0
  end
end
