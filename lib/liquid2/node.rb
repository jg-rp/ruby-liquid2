# frozen_string_literal: true

require_relative "utils/string_io"

module Liquid2
  # The base class for all nodes in a Liquid syntax tree.
  class Node
    attr_reader :blank

    # @param token [[Symbol, String?, Integer]]
    def initialize(token)
      @token = token
      @blank = true
    end

    def render(_context, _buffer)
      raise "nodes must implement `render: (RenderContext, _Buffer) -> Integer`"
    end
  end

  # An node representing a block of Liquid markup.
  # Essentially an array of other nodes and strings.
  # @param token [[Symbol, String?, Integer]]
  # @param nodes [Array[Node | String]]
  class Block < Node
    def initialize(token, nodes)
      super(token)
      @nodes = nodes
      # TODO: @blank = nodes.all?(&:blank)
    end

    def render(context, buffer)
      if context.env.suppress_blank_control_flow_blocks && @blank
        buf = NullIO.new
        @nodes.each do |node|
          case node
          when String
            buf.write(node)
          else
            node.render(context, buf)
          end
          return 0 unless context.interrupts.empty?
        end
        0
      else
        count = 0
        @nodes.each do |node|
          count += case node
                   when String
                     buffer.write(node)
                   else
                     node.render(context, buffer)
                   end
          return count unless context.interrupts.empty?
        end
        count
      end
    end
  end

  # A Liquid block guarded by an expression.
  # Only if the expression evaluates to a truthy value will the block be rendered.
  class ConditionalBlock < Node
    attr_reader :expression, :block

    def initialize(token, expression, block)
      super(token)
      @expression = expression
      @block = block
      @blank = block.blank
    end

    def render(context, buffer)
      @expression.evaluate(context) ? @block.render(context, buffer) : 0
    end
  end
end
