# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _raw_ tag.
  class RawTag < Tag
    # @param parser [Parser]
    # @return [RawTag]
    def self.parse(token, parser)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      # TODO: apply whitespace control to raw text?
      # Shopify/liquid does not apply whitespace control to raw content.
      raw = parser.eat(:token_raw)
      parser.eat_empty_tag("endraw")
      new(token, raw[1] || raise)
    end

    # @param text [String]
    def initialize(token, text)
      super(token)
      @text = text
      @blank = false
    end

    def render(_context, buffer)
      buffer << @text
    end
  end
end
