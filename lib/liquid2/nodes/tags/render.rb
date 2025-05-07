# frozen_string_literal: true

require_relative "../../tag"
require_relative "for"

module Liquid2
  DISABLED_TAGS = Set["include"]

  # The standard _render_ tag.
  class RenderTag < Tag
    # @param parser [Parser]
    # @return [RenderTag]
    def self.parse(token, parser)
      name = parser.parse_string
      repeat = false
      var = nil # : Expression?
      as = nil # : Identifier?

      if parser.current_kind == :token_for && !%i[token_comma
                                                  token_colon].include?(parser.peek_kind)
        parser.next
        repeat = true
        var = parser.parse_primary
        if parser.current_kind == :token_as
          parser.next
          as = parser.parse_identifier
        end
      elsif parser.current_kind == :token_with && !%i[token_comma
                                                      token_colon].include?(parser.peek_kind)
        parser.next
        var = parser.parse_primary
        if parser.current_kind == :token_as
          parser.next
          as = parser.parse_identifier
        end
      end

      parser.next if parser.current_kind == :token_comma
      args = parser.parse_keyword_arguments
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, name, repeat, var, as, args)
    end

    # @param name [String]
    # @param repeat [bool]
    # @param var [Expression?]
    # @param as [Identifier?]
    # @param args [Array<KeywordArgument> | nil]
    def initialize(token, name, repeat, var, as, args)
      super(token)
      @template_name = name
      @repeat = repeat
      @var = var
      @as = as&.name
      @args = args
      @blank = false
    end

    def render(context, buffer)
      template = context.env.get_template(@template_name, context: context, tag: :render)
      namespace = @args.to_h { |arg| [arg.name, context.evaluate(arg.value)] }

      ctx = context.copy(namespace,
                         template: template,
                         disabled_tags: DISABLED_TAGS,
                         carry_loop_iterations: true)

      if @var
        val = context.evaluate(@var || raise)
        key = @as || template.name.split(".").first

        if @repeat && val.respond_to?(:[]) && val.respond_to?(:size)
          ctx.raise_for_loop_limit(length: val.size)

          forloop = ForLoop.new(
            key, val.size, context.env.undefined("parentloop")
          )

          namespace["forloop"] = forloop

          index = 0
          while index < val.length
            namespace[key] = val[index]
            index += 1
            forloop.next
            template.render_with_context(ctx, buffer, partial: true, block_scope: true)
          end
        else
          namespace[key] = val
          template.render_with_context(ctx, buffer, partial: true, block_scope: true)
        end
      else
        template.render_with_context(ctx, buffer, partial: true, block_scope: true)
      end
    rescue LiquidTemplateNotFoundError => e
      e.token = @template_name
      e.template_name = context.template.full_name
      raise e
    end

    def children(static_context, include_partials: true)
      return [] unless include_partials

      name = static_context.evaluate(@template_name)
      template = static_context.env.get_template(name.to_s, context: static_context, tag: :include)
      template.ast
    rescue LiquidTemplateNotFoundError => e
      e.token = @token
      e.template_name = static_context.template.full_name
      raise e
    end

    def expressions
      exprs = [@template_name]
      exprs << @var if @var
      exprs.concat(@args.map(&:value))
      exprs
    end

    def partial_scope
      scope = @args.map { |arg| Identifier.new([:token_word, arg.name, arg.token.last]) }

      if @var
        if @as
          scope << @as # steep:ignore
        elsif @template_name.is_a?(String)
          scope << Identifier.new([:token_word, @template_name.split(".").first, @token.last])
        end
      end

      Partial.new(@template_name, :isolated, scope)
    end
  end
end
