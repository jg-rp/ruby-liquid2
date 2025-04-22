# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _case_ tag.
  class CaseTag < Node
    END_BLOCK = Set["endcase", "when", "else"]
    WHEN_DELIM = Set[:token_comma, :token_or]

    def self.parse(parser)
      token = parser.previous
      expression = parser.parse_primary
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      parser.eat(:token_other) if parser.current_kind == :token_other

      whens = [] # : Array[MultiEqualBlock]
      default = nil # : Block?

      whens << parse_when(parser, expression) while parser.tag?("when")

      if parser.tag?("else")
        parser.eat_empty_tag("else")
        default = parser.parse_block(END_BLOCK)
      end

      parser.eat_empty_tag("endcase")
      new(token, expression, whens, default)
    end

    # @return [MultiEqualBlock]
    def self.parse_when(parser, expr)
      parser.eat(:token_tag_start)
      parser.skip_whitespace_control
      token = parser.eat(:token_tag_name)

      parser.next if parser.current_kind == :token_comma

      args = [] # : Array[Expression]

      loop do
        args << parser.parse_primary(infix: false)
        break unless WHEN_DELIM.member?(parser.current_kind)

        parser.next
      end

      parser.carry_whitespace_control
      parser.eat(:token_tag_end)

      block = parser.parse_block(END_BLOCK)
      MultiEqualBlock.new(token, expr, args, block)
    end

    def initialize(token, expression, whens, default)
      super(token)
      @expression = expression
      @whens = whens
      @default = default
      @blank = whens.map(&:blank).all? && (!default || default.blank)
    end

    def render(context, buffer)
      rendered = false
      index = 0
      while (node = @whens[index])
        rendered_ = node.render(context, buffer)
        rendered ||= rendered_
        index += 1
      end

      (@default || raise).render(context, buffer) if @default && !rendered
    end
  end

  # A Liquid block guarded by any one of multiple expressions.
  class MultiEqualBlock < Node
    # @param left [Expression]
    # @param conditions [Array<Expression>]
    # @param block [Block]
    def initialize(token, left, conditions, block)
      super(token)
      @left = left
      @conditions = conditions
      @block = block
      @blank = block.blank
    end

    def render(context, buffer)
      left = context.evaluate(@left)
      if @conditions.map { |right| Liquid2.eq(left, context.evaluate(right)) }.any?
        @block.render(context, buffer)
        true
      else
        false
      end
    end
  end
end
