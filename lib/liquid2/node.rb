# frozen_string_literal: true

module Liquid2
  # The base class for all nodes.
  class Node
    attr_reader :tokens, :children, :blank

    # @param children [Array<Node | Token>]
    def initialize(children)
      @children = children
      @blank = true
    end

    def start = @children.first.start

    def full_start = @tokens.first.full_start

    def end = @tokens.last.end

    def text = @tokens.first.text + @tokens.to_enum.drop(1).map(&:full_text)

    def full_text = @tokens.map(&:full_text).join

    alias to_s full_text

    def to_h = { kind: self.class, children: @children.map(&:to_h) }
  end

  # Base class for all tags.
  class Tag < Node
    # Render this node to the output buffer.
    # @param context [RenderContext]
    # @param buffer [StringIO]
    # @return [Integer] The number of bytes written to _buffer_.
    def render(_context, _buffer)
      raise "nodes must implement `render(context, buffer)`."
    end
  end

  # The base class for all expressions.
  class Expression < Node
    # Evaluate this expression.
    # @return [untyped] The result of evaluating this expression.
    def evaluate(_context)
      raise "expressions must implement `evaluate(context)`."
    end
  end
end
