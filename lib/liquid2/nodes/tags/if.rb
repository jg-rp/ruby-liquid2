# frozen_string_literal: true

require "set"
require_relative "../../tag"

module Liquid2
  # The standard _if_ tag
  class IfTag < Tag
    END_TAG = "endif"
    END_BLOCK = Set["else", "elsif", "endif"].freeze

    # @param parser [Parser]
    # @return [IfTag]
    def self.parse(parser)
      token = parser.previous # token_tag_name
      expression = BooleanExpression.new(parser.current, parser.parse_primary)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)

      block = parser.parse_block(self::END_BLOCK)
      alternatives = [] # : Array[ConditionalBlock]
      alternatives << parse_elsif(parser) while parser.tag?("elsif")

      if parser.tag?("else")
        parser.eat_empty_tag("else")
        default = parser.parse_block(self::END_BLOCK)
      else
        default = nil
      end

      parser.eat_empty_tag(self::END_TAG)
      new(token, expression, block, alternatives, default)
    end

    # @return [ConditionalBlock]
    def self.parse_elsif(parser)
      parser.eat(:token_tag_start)
      parser.skip_whitespace_control
      token = parser.eat(:token_tag_name)

      expression = BooleanExpression.new(parser.current, parser.parse_primary)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)

      block = parser.parse_block(self::END_BLOCK)
      ConditionalBlock.new(token, expression, block)
    end

    # @param token [[Symbol, String?, Integer]]
    # @param expression [Expression]
    # @param block [Block]
    # @param alternatives [Array<[ConditionalBlock]>]
    # @param default [Block?]
    def initialize(token, expression, block, alternatives, default)
      super(token)
      @expression = expression
      @block = block
      @alternatives = alternatives
      @default = default
      @blank = block.blank && alternatives.all?(&:blank) && (!default || default.blank)
    end

    def render(context, buffer)
      return @block.render(context, buffer) if context.evaluate(@expression)

      index = 0
      while (alt = @alternatives[index])
        index += 1
        return alt.block.render(context, buffer) if context.evaluate(alt.expression)
      end

      (@default || raise).render(context, buffer) if @default
    end
  end
end
