# frozen_string_literal: true

require_relative "../../node"
require_relative "for"

module Liquid2
  DISABLED_TAGS = Set["include"]

  # The standard _render_ tag.
  class RenderTag < Tag
    # @param stream [TokenStream]
    # @param parser [Parser]
    # @return [RenderTag]
    def self.parse(stream, parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      name = parser.parse_string(stream)
      raise LiquidTypeError, "expected a string literal" unless name.is_a?(StringLiteral)

      children << name

      repeat = false
      var = nil # : Expression?
      as = nil # : Identifier?

      if stream.current.kind == :token_for && !%i[token_comma
                                                  token_colon].include?(stream.peek.kind)
        children << stream.next
        repeat = true
        var = parser.parse_primary(stream)
        children << var
        if stream.current.kind == :token_as
          children << stream.next
          as = parser.parse_identifier(stream)
          children << as
        end
      elsif stream.current.kind == :token_with && !%i[token_comma
                                                      token_colon].include?(stream.peek.kind)
        children << stream.next
        var = parser.parse_primary(stream)
        children << var
        if stream.current.kind == :token_as
          children << stream.next
          as = parser.parse_identifier(stream)
          children << as
        end
      end

      children << stream.next if stream.current.kind == :token_comma
      args = parser.parse_keyword_arguments(stream)
      children.push(*args)
      children << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      new(children, name, repeat, var, as, args)
    end

    # @param children Array[Token | Node]
    # @param name [StringLiteral]
    # @param repeat [bool]
    # @param var [Expression?]
    # @param as [Identifier?]
    # @param args [Array<KeywordArgument> | nil]
    def initialize(children, name, repeat, var, as, args)
      super(children)
      @name = name
      @repeat = repeat
      @var = var
      @as = as&.text
      @args = args
    end

    def render(context, buffer)
      template = context.env.get_template(@name.value, context: context, tag: :render)
      namespace = @args.to_h { |arg| arg.evaluate(context) }
      count = 0

      ctx = context.copy(namespace,
                         template: template,
                         disabled_tags: DISABLED_TAGS,
                         carry_loop_iterations: true)

      if @var
        val = (@var || raise).evaluate(ctx)
        key = @as || template.name.split(".").first

        if @repeat && val.respond_to?(:each) && val.respond_to(:size)
          ctx.raise_for_loop_limit(length: val.size)

          forloop = ForLoop.new(
            key, val.to_enum, val.size, context.env.undefined("parentloop")
          )

          namespace["forloop"] = forloop

          forloop.each do |item|
            namespace[key] = item
            count += template.render_with_context(ctx, buffer, partial: true, block_scope: true)
          end
        else
          namespace[key] = val
          count += template.render_with_context(ctx, buffer, partial: true, block_scope: true)
        end
      else
        count += template.render_with_context(ctx, buffer, partial: true, block_scope: true)
      end

      count
    rescue LiquidTemplateNotFoundError => e
      e.node_or_token = @name
      e.template_name = context.template.full_name
      raise e
    end
  end
end
