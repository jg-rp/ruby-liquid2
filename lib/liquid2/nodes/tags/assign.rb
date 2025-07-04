# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _assign_ tag.
  class AssignTag < Tag
    # @param parser [Parser]
    # @return [AssignTag]
    def self.parse(token, parser)
      name = parser.parse_identifier(trailing_question: false)
      parser.eat(:token_assign, "malformed identifier or missing assignment operator")
      expression = parser.parse_filtered_expression
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, name, expression)
    end

    # @param token [[Symbol, String?, Integer]]
    # @param name [Identifier]
    # @param expression [Expression]
    def initialize(token, name, expression)
      super(token)
      @name = name
      @expression = expression
    end

    def render(context, _buffer)
      context.assign(@name.name, context.evaluate(@expression))
    end

    def expressions = [@expression]
    def template_scope = [@name]
  end
end
