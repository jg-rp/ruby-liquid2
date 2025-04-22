# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # `{% # comment %}` style comments.
  class InlineComment < Node
    def self.parse(parser)
      token = parser.previous # token_tag_name
      comment = parser.eat(:token_comment)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, comment[1] || "")
    end

    # @param text [String]
    def initialize(token, text)
      super(token)
      @text = text
      # TODO: validate lines start with a hash
    end

    def render(_context, _buffer) = 0
  end
end
