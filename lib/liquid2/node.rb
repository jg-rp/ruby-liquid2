# frozen_string_literal: true

require_relative "utils/string_io"

module Liquid2
  # The base class for all nodes in a Liquid syntax tree.
  class Node
    attr_reader :children, :blank

    WC_MAP = {
      "" => :whitespace_control_default,
      "-" => :whitespace_control_minus,
      "+" => :whitespace_control_plus,
      "~" => :whitespace_control_tilde
    }.freeze

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

  # An node representing a block of Liquid markup. Essentially an array of other nodes.
  class Block < Node
    def initialize(children)
      super
      @blank = children.all?(&:blank)
    end

    def render(context, buffer)
      if context.env.suppress_blank_control_flow_blocks && @blank
        buf = NullIO.new
        @children.each { |node| node.render(context, buf) } # steep:ignore
        0
      else
        @children.map { |node| node.render(context, buffer) }.sum # steep:ignore
      end
    end
  end

  class ConditionalBlock < Node
    attr_reader :expression, :block

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
    attr_reader :wc

    def initialize(children)
      super
      @wc = @children.map do |child|
        WC_MAP.fetch(child.text) if child.is_a?(Token) && child.kind == :token_whitespace_control
      end.compact
    end

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
