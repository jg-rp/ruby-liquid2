# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _comment_ tag.
  class BlockComment < Tag
    attr_reader :text

    def self.parse(token, parser)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      comment = parser.eat(:token_comment)
      parser.eat_empty_tag("endcomment")
      new(token, comment[1] || raise)
    end

    # @param text [String]
    def initialize(token, text)
      super(token)
      @text = text
    end

    def render(_context, _buffer) = 0
  end
end
