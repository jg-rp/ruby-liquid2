# frozen_string_literal: true

require "set"
require_relative "../../node"

module Liquid2
  # The standard _if_ tag
  class IfTag < Node
    END_TAG = Set["endif"].freeze
    END_BLOCK = Set["else", "elsif", "endif"].freeze

    def self.parse(stream, parser)
      # TODO: helper method eat_tag_preamble
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      expression = BooleanExpression.new(parser.parse_primary(stream))

      # TODO: skip until ..
      children << expression << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      block = parser.parse_block(stream, END_BLOCK)
      children << block

      alternatives = []
      alternatives << parse_elsif(stream, parser) while stream.tag?("elsif")
      children.push(*alternatives)

      if stream.tag?("else")
        children.push(*stream.eat_empty_tag("else"))
        default = parser.parse_block(stream, END_BLOCK)
        children << default
      else
        default = nil
      end

      children.push(*stream.eat_empty_tag("endif"))
      new(children, expression, block, alternatives, default)
    end

    # @return [ConditionalBlock]
    def self.parse_elsif(stream, parser)
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      expression = BooleanExpression.new(parser.parse_primary(stream))

      # TODO: skip until ..
      children << expression << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      block = parser.parse_block(stream, END_BLOCK)
      children << block
      ConditionalBlock.new(children, expression, block)
    end

    # @param children [Array<Token|Node>]
    # @param expression [Expression]
    # @param block [Block]
    # @param alternatives [Array<[ConditionalBlock]>]
    # @param default [Block?]
    def initialize(children, expression, block, alternatives, default)
      super(children)
      @expression = expression
      @block = block
      @alternatives = alternatives
      @default = default
    end

    def render(context, buffer)
      return @block.render(context, buffer) if @expression.evaluate(context)

      @alternatives.each do |alt|
        return alt.block.render(context, buffer) if alt.expression.evaluate(context)
      end

      return @default.render(context, buffer) if @default

      0
    end
  end
end
