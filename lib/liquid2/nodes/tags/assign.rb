# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _assign_ tag.
  class AssignTag < Node
    # @param stream [TokenStream]
    # @param parser [Parser]
    # @return [AssignTag]
    def self.parse(parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      name = parser.parse_identifier(stream, trailing_question: false)
      children << name << stream.eat(:token_assign)
      expression = parser.parse_filtered_expression(stream)
      children << expression << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      new(children, name, expression)
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
      context.assign(@name, @expression.evaluate(context))
      0
    end
  end
end
