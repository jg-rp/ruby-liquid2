# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _decrement_ tag.
  class DecrementTag < Tag
    # @param parser [Parser]
    # @return [DecrementTag]
    def self.parse(token, parser)
      name = parser.parse_identifier(trailing_question: false)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, name)
    end

    # @param name [Identifier]
    def initialize(token, name)
      super(token)
      @name = name.name
    end

    def render(context, buffer)
      buffer << context.decrement(@name).to_s
    end
  end
end
