# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _case_ tag.
  class CaseTag < Tag
    END_BLOCK = Set["endcase", "when", "else"]

    def self.parse(stream, parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      expression = parser.parse_primary(stream)
      children << expression << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      children << stream.eat(:token_other) if stream.current.kind == :token_other
      # TODO: skip junk between `{% case .. %}` and first `{% when %}`.

      whens = [] # : Array[MultiEqualBlock]
      default = nil # : Block?

      whens << parse_when(stream, parser, expression) while stream.tag?("when")
      children.push(*whens)

      if stream.tag?("else")
        children.push(*stream.eat_empty_tag("else"))
        default = parser.parse_block(stream, END_BLOCK)
        children << default
      end

      children.push(*stream.eat_empty_tag("endcase")) if stream.tag?("endcase")
      new(children, expression, whens, default)
    end

    # @return [MultiConditionalBlock]
    def self.parse_when(stream, parser, expr)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      children << stream.next if stream.current.kind == :token_comma

      args = [] # : Array[Expression]

      loop do
        item = parser.parse_primary(stream)
        args << item
        children << item
        break unless stream.current.kind == :token_comma || stream.word?("or")

        children << stream.next
      end

      children << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      block = parser.parse_block(stream, END_BLOCK)
      children << block
      MultiEqualBlock.new(children, expr, args, block)
    end

    def initialize(children, expression, whens, default)
      super(children)
      @expression = expression
      @whens = whens
      @default = default
      @blank = whens.map(&:blank).all? && (!default || default.blank)
    end

    def render(context, buffer)
      count = 0
      @whens.each do |node|
        count += node.render(context, buffer)
      end

      count += (@default || raise).render(context, buffer) if @default && count.zero?
      count
    end
  end

  # A Liquid block guarded by any one of multiple expressions.
  class MultiEqualBlock < Node
    # @param children [Array<Token | Node>]
    # @param left [Expression]
    # @param conditions [Array<Expression>]
    # @param block [Block]
    def initialize(children, left, conditions, block)
      super(children)
      @left = left
      @conditions = conditions
      @block = block
      @blank = block.blank
    end

    def render(context, buffer)
      left = @left.evaluate(context)
      if @conditions.map { |right| Liquid2.eq(left, right.evaluate(context)) }.any?
        @block.render(context, buffer)
      else
        0
      end
    end
  end
end
