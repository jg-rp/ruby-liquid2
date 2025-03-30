# frozen_string_literal: true

require_relative "utils/string_io"

module Liquid2
  # The base class for all nodes in a Liquid syntax tree.
  class Node
    attr_reader :children, :blank

    # @param children [Array<Node | Token>]
    def initialize(children)
      @children = children
      @blank = true
    end

    # The index of the start of this node in template source text.
    def start = @children.first.start

    # The index of the start of this node in template source text, including leading whitespace.
    def full_start = @children.first.full_start

    # The index of the end of this node in template source text.
    def end = @children.last.end

    # Liquid markup for this node.
    def text = @children.first.text + @children.to_enum.drop(1).map(&:full_text).join

    # Liquid markup for this node, including leading whitespace.
    def full_text = @children.map(&:full_text).join

    alias to_s full_text

    # For debugging.
    def dump = { kind: self.class, children: @children.map(&:dump) }
  end

  class RootNode < Node; end
  class Skipped < Node; end
  class Missing < Node; end

  class Block < Node
    def initialize(children, nodes)
      super(children)
      @nodes = nodes
      @blank = nodes.all(&:blank)
    end

    def render(context, buffer)
      if context.env.suppress_blank_control_flow_blocks && @blank
        buf = NullIO.new
        @nodes.each { |node| node.render(context, buf) }
        0
      else
        @nodes.map { |node| node.render(context, buffer) }.sum
      end
    end
  end

  class ConditionalBlockNode
    def initialize(children, expression, block)
      super(children)
      @expression = expression
      @block = block
      @blank = block.blank
    end

    def render(context, buffer)
      @expression.evaluate(context) ? @block.render(context, buffer) : 0
    end
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
      raise "expressions must implement `evaluate(context)` (#{self.class})."
    end
  end
end
