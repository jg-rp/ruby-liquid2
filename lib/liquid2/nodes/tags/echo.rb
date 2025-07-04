# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _echo_ tag.
  class EchoTag < Tag
    # @param parser [Parser]
    # @return [EchoTag]
    def self.parse(token, parser)
      expression = unless %i[token_whitespace_control token_tag_end].include?(parser.current_kind)
                     parser.parse_filtered_expression
                   end
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

    def expressions = [@expression]
  end
end
