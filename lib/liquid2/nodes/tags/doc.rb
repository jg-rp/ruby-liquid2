# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _doc_ tag.
  class DocTag < Tag
    def self.parse(token, parser)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      text_token = parser.eat(:token_doc)
      parser.eat_empty_tag("enddoc")
      new(token, text_token[1] || raise)
    end

    # @param text [String]
    def initialize(token, text)
      super(token)
      @text = text
    end

    def render(_context, _buffer) = 0
  end
end
