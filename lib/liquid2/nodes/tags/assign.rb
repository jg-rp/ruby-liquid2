# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _assign_ tag.
  class AssignTag < Node
    # @param parser [Parser]
    # @return [AssignTag]
    def self.parse(parser)
      token = parser.previous # token_tag_name
      name = parser.parse_identifier(trailing_question: false)
      parser.eat(:token_assign)
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
      @name = name.name
      @expression = expression
    end

    def render(context, _buffer)
      context.assign(@name, context.evaluate(@expression))
    end
  end
end
