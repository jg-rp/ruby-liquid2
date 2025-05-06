# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The _extends_ tag.
  class ExtendsTag < Tag
    attr_reader :template_name

    # @param token [[Symbol, String?, Integer]]
    # @param parser [Parser]
    # @return [ExtendsTag]
    def self.parse(token, parser)
      name = parser.parse_name
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, name)
    end

    def initialize(token, name)
      super(token)
      @template_name = name
      @blank = false
    end

    def render(context, buffer)
      base_template = stack_blocks(context, context.template)
      context.extend({}, template: base_template) do
        base_template&.render_with_context(context, buffer)
      end
      context.tag_namespace[:extends].clear
      context.interrupts << :stop_render
    end

    def children(static_context, include_partials: true)
      return [] unless include_partials

      begin
        parent = static_context.env.get_template(
          @template_name,
          context: static_context,
          tag: "extends"
        )
        parent.ast
      rescue LiquidTemplateNotFoundError => e
        e.token = @token
        e.template_name = static_context.template.full_name
        raise e
      end
    end

    def partial_scope
      Partial.new(@template_name, :inherited, [])
    end

    protected

    # Visit all templates in the inheritance chain and build a stack for each `block` tag.
    def stack_blocks(context, template)
      # @type var stacks: Hash[String, Array[untyped]]
      stacks = context.tag_namespace[:extends]

      # Guard against recursive `extends`.
      seen_extends = Set[] # : Set[String]

      # @type var stack_blocks_: ^(Template) -> Template?
      stack_blocks_ = lambda do |template_|
        extends_nodes, block_nodes = inheritance_nodes(context, template_)
        template_name = template_.path || template_.name

        if extends_nodes.length > 1
          raise TemplateInheritanceError.new("too many 'extends' tags", extends_nodes[1].token,
                                             template_name: template_name)
        end

        # Identify duplicate blocks.
        seen_blocks = Set[] # : Set[String]

        block_nodes.each do |block|
          if seen_blocks.include?(block.block_name)
            raise TemplateInheritanceError.new("duplicate block #{block.block_name.inspect}",
                                               block.token, template_name: template_name)
          end

          seen_blocks.add(block.block_name)

          stack = stacks[block.block_name]
          required = !stack.empty? && !block.required ? false : block.required
          # [block, required, template name, parent]
          # [BlockTag, bool, String, untyped?]
          stack << [block, required, template_name, nil]
          # Populate parent block.
          stack[-2][-1] = stack.last if stack.length > 1
        end

        return nil if extends_nodes.empty? # steep:ignore

        extends_node = extends_nodes.first

        if seen_extends.include?(extends_node.template_name)
          raise TemplateInheritanceError.new(
            "circular extends #{extends_node.template_name.inspect}",
            extends_node.token,
            template_name: template_name
          )
        end

        seen_extends.add(extends_node.template_name)

        begin
          context.env.get_template(extends_node.template_name, context: context, tag: "extends")
        rescue LiquidTemplateNotFoundError => e
          e.token = extends_node.token
          e.template_name = template_.full_name
          raise e
        end
      end

      # @type var next_template: Template?
      base = next_template = stack_blocks_.call(template)

      while next_template
        next_template = stack_blocks_.call(next_template)
        base = next_template if next_template
      end

      base
    end

    # Traverse the template's syntax tree looking for `{% extends %}` and `{% block %}`.
    # @return [[Array[ExtendsTag], Array[BlockTag]]]
    def inheritance_nodes(context, template)
      extends_nodes = [] # : Array[ExtendsTag]
      block_nodes = [] # : Array[BlockTag]

      # @type var visit: ^(Node) -> void
      visit = lambda do |node|
        extends_nodes << node if node.is_a?(ExtendsTag)
        block_nodes << node if node.is_a?(BlockTag)

        node.children(context, include_partials: false).each do |child|
          visit.call(child) if child.is_a?(Node)
        end
      end

      template.ast.each { |node| visit.call(node) if node.is_a?(Node) }

      [extends_nodes, block_nodes]
    end
  end

  # The _block_ tag.
  class BlockTag < Tag
    attr_reader :block_name, :required, :block

    END_BLOCK = Set["endblock"]

    # @param token [[Symbol, String?, Integer]]
    # @param parser [Parser]
    # @return [BlockTag]
    def self.parse(token, parser)
      block_name = parser.parse_name
      required = if parser.current_kind == :token_required
                   parser.next
                   true
                 else
                   false
                 end

      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      block = parser.parse_block(END_BLOCK)
      parser.eat_empty_tag("endblock")
      new(token, block_name, block, required: required)
    end

    def initialize(token, name, block, required:)
      super(token)
      @block_name = name
      @block = block
      @required = required
      @blank = false
    end

    def render(context, buffer)
      # @type var stack: Array[[BlockTag, bool, String, untyped?]]
      stack = context.tag_namespace[:extends][@block_name]

      if stack.empty?
        # This base block is being rendered directly.
        if @required
          raise RequiredBlockError.new("block #{@block_name.inspect} is required",
                                       @token)
        end

        context.extend({ "block" => BlockDrop.new(token, context, @block_name, nil) }) do
          @block.render(context, buffer)
        end

        return
      end

      block_tag, required, template_name, parent = stack.first

      if required
        raise RequiredBlockError.new("block #{@block_name.inspect} is required", @token,
                                     template_name: template_name)
      end

      namespace = { "block" => BlockDrop.new(token, context, @block_name, parent) }
      block_context = context.copy(namespace, carry_loop_iterations: true, block_scope: true)
      block_tag.block.render(block_context, buffer)
    end

    def children(_static_context, include_partials: true)
      [@block]
    end

    def block_scope
      [Identifier.new([:token_word, "block", @token.last])]
    end
  end

  # A `block` object available within `{% block %}` tags.
  class BlockDrop
    attr_reader :token

    # @param token [[Symbol, String?, Integer]]
    # @param context [RenderContext]
    # @param name [String]
    # @param parent [[BlockTag, bool, String, Block?]?]
    def initialize(token, context, name, parent)
      @token = token
      @context = context
      @name = name
      @parent = parent
    end

    def to_s = "BlockDrop(#{@name})"

    def key?(key)
      key == "super"
    end

    def [](key)
      return @context.env.undefined(key, node: self) if key != "super" || @parent.nil?

      parent = @parent || raise
      buf = +""
      namespace = { "block" => BlockDrop.new(parent.first.token,
                                             @context,
                                             parent[2],
                                             parent.last) }
      @context.extend(namespace) do
        parent.first.block.render(@context, buf)
      end

      buf.freeze
    end
  end
end
