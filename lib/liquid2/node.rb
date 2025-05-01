# frozen_string_literal: true

module Liquid2
  # The base class for all nodes in a Liquid syntax tree.
  class Node
    attr_reader :token
    attr_accessor :blank

    # @param token [[Symbol, String?, Integer]]
    def initialize(token)
      @token = token
      @blank = true
    end

    def render(_context, _buffer)
      raise "nodes must implement `render: (RenderContext, String) -> void`"
    end

    def render_with_disabled_tag_check(context, buffer)
      if context.disabled_tags.empty? ||
         !is_a?(Tag) ||
         !context.disabled_tags.include?(@token[1] || raise)
        return render(context, buffer)
      end

      raise DisabledTagError.new("#{@token[1]} is not allowed in this context", @token)
    end

    # Return all children of this node.
    def children(_static_context, include_partials: true) = []

    # Return this node's expressions.
    def expressions = []

    # Return variables this node adds to the template local scope.
    def template_scope = []

    # Return variables this nodes adds to its block scope.
    def block_scope = []

    # Return information about a partial template loaded by this node.
    def partial_scope = nil
  end

  # Partial template meta data.
  class Partial
    attr_reader :name, :scope, :in_scope

    # @param name [Expression | String] The name of the partial template.
    # @param scope [:shared | :isolated | :inherited] A symbol indicating the kind of
    #   scope the partial template should have when loaded.
    # @param in_scope [Array[Identifier]] Names that will be added to the scope of the
    #   partial template.
    def initialize(name, scope, in_scope)
      @name = name
      @scope = scope
      @in_scope = in_scope
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
      @blank = nodes.all? do |n|
        (n.is_a?(String) && n.match(/\A\s*\Z/)) || (n.is_a?(Node) && n.blank)
      end
    end

    def render(context, buffer)
      buffer = +"" if context.env.suppress_blank_control_flow_blocks && @blank
      index = 0
      while (node = @nodes[index])
        index += 1
        case node
        when String
          buffer << node
        else
          node.render_with_disabled_tag_check(context, buffer)
        end

        context.raise_for_output_limit(buffer.bytesize)
        return unless context.interrupts.empty?
      end
    end

    def children(_static_context, include_partials: true) = @nodes
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

    def children(_static_context, include_partials: true) = [@block]
    def expressions = [@expression]
  end
end
