# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _echo_ tag.
  class EchoTag < Tag
    # @param stream [TokenStream]
    # @param parser [Parser]
    # @return [EchoTag]
    def self.parse(stream, parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      expression = parser.parse_filtered_expression(stream)
      children << expression << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      new(children, expression)
    end

    def initialize(children, expression)
      super(children)
      @expression = expression
      @blank = false
    end

    def render(context, buffer)
      buffer.write(Liquid2.to_output_s(@expression.evaluate(context)))
    end
  end
end
