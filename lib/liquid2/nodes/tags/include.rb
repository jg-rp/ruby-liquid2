# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _include_ tag.
  class IncludeTag < Tag
    # @param parser [Parser]
    # @return [IncludeTag]
    def self.parse(token, parser)
      name = parser.parse_primary

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

    # @param name [Expression]
    # @param repeat [bool]
    # @param var [Expression?]
    # @param as [Identifier?]
    # @param args [Array<KeywordArgument> | nil]
    def initialize(token, name, repeat, var, as, args)
      super(token)
      @name = name
      @repeat = repeat
      @var = var
      @as = as
      @args = args
      @blank = false
    end

    def render(context, buffer)
      name = context.evaluate(@name)
      template = context.env.get_template(name.to_s, context: context, tag: :include)
      namespace = @args.to_h { |arg| [arg.name, context.evaluate(arg.value)] }

      context.extend(namespace, template: template) do
        if @var
          val = context.evaluate(@var || raise)
          key = @as&.name || template.name.split(".").first

          if val.is_a?(Array)
            context.raise_for_loop_limit(length: val.size)
            index = 0
            while index < val.length
              namespace[key] = val[index]
              template.render_with_context(context, buffer, partial: true, block_scope: false)
              index += 1
            end
          else
            namespace[key] = val
            template.render_with_context(context, buffer, partial: true, block_scope: false)
          end
        else
          template.render_with_context(context, buffer, partial: true, block_scope: false)
        end
      end
    rescue LiquidTemplateNotFoundError => e
      e.token = @token
      e.template_name = context.template.full_name unless context.template.full_name.empty?
      raise e
    end

    def children(static_context, include_partials: true)
      return [] unless include_partials

      name = static_context.evaluate(@name)
      template = static_context.env.get_template(name.to_s, context: static_context, tag: :include)
      template.ast
    rescue LiquidTemplateNotFoundError => e
      e.token = @token
      e.template_name = static_context.template.full_name
      raise e
    end

    def expressions
      exprs = [@name]
      exprs << @var if @var
      exprs.concat(@args.map(&:value))
      exprs
    end

    def partial_scope
      scope = @args.map { |arg| Identifier.new([:token_word, arg.name, arg.token.last]) }

      if @var
        if @as
          scope << @as # steep:ignore
        elsif @name.is_a?(String)
          scope << Identifier.new([:token_word, @name.split(".").first, @token.last])
        end
      end

      Partial.new(@name, :shared, scope)
    end
  end
end
