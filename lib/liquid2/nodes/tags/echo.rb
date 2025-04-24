# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _echo_ tag.
  class EchoTag < Node
    # @param parser [Parser]
    # @return [EchoTag]
    def self.parse(token, parser)
      expression = parser.parse_filtered_expression
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, expression)
    end

    def initialize(token, expression)
      super(token)
      @expression = expression
      @blank = false
    end

    def render(context, buffer)
      buffer << Liquid2.to_output_s(context.evaluate(@expression))
    end
  end
end
