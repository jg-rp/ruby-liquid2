# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The _macro_ tag.
  class MacroTag < Tag
    attr_reader :macro_name, :params, :block

    END_BLOCK = Set["endmacro"]

    # @param token [[Symbol, String?, Integer]]
    # @param parser [Parser]
    # @return [MacroTag]
    def self.parse(token, parser)
      name = parser.parse_name
      parser.next if parser.current_kind == :token_comma
      params = parser.parse_parameters
      parser.next if parser.current_kind == :token_comma
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      block = parser.parse_block(END_BLOCK)
      parser.eat_empty_tag("endmacro")
      new(token, name, params, block)
    end

    def initialize(token, name, params, block)
      super(token)
      @macro_name = name
      @params = params
      @block = block
      @blank = true
    end

    def render(context, _buffer)
      # Macro tags don't render or evaluate anything, just store their parameter list
      # and block on the render context so it can be called later by a `call` tag.
      context.tag_namespace[:macros][@macro_name] = [@params, @block]
    end

    def children(_static_context, include_partials: true) = [@block]
    def expressions = @params.values.filter_map(&:value)

    def block_scope
      [
        Identifier.new([:token_word, "args", @token.last]),
        Identifier.new([:token_word, "kwargs", @token.last]),
        *@params.values.map { |param| Identifier.new([:token_word, param.name, param.token.last]) }
      ]
    end
  end

  # The _call_ tag.
  class CallTag < Tag
    attr_reader :macro_name, :args, :kwargs

    DISABLED_TAGS = Set["include", "block"]

    # @param token [[Symbol, String?, Integer]]
    # @param parser [Parser]
    # @return [CallTag]
    def self.parse(token, parser)
      name = parser.parse_name
      parser.next if parser.current_kind == :token_comma
      args, kwargs = parser.parse_arguments
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, name, args, kwargs)
    end

    def initialize(token, name, args, kwargs)
      super(token)
      @macro_name = name
      @args = args
      @kwargs = kwargs
      @blank = false
    end

    def render(context, buffer)
      # @type var params: Hash[String, Parameter]?
      # @type var block: Block
      params, block = context.tag_namespace[:macros][@macro_name]

      unless params
        buffer << Liquid2.to_output_string(context.env.undefined(@macro_name, node: self))
        return
      end

      # Parameter names mapped to default values. :undefined is used if there is no default.
      args = params.values.to_h { |p| [p.name, p.value] }
      excess_args = [] # : Array[untyped]
      excess_kwargs = {} # : Hash[String, untyped]

      # Update args with positional arguments.
      # Keyword arguments are pushed to the end if they appear before positional arguments.
      names = args.keys
      length = @args.length
      index = 0
      while index < length
        name = names[index]
        expr = @args[index]
        if name.nil?
          excess_args << expr
        else
          args[name] = expr
        end
        index += 1
      end

      # Update args with keyword arguments.
      @kwargs.each do |arg|
        if params.include?(arg.name)
          # This has the potential to override a positional argument.
          args[arg.name] = arg.value
        else
          excess_kwargs[arg.name] = arg.value
        end
      end

      # @type var namespace: Hash[String, untyped]
      namespace = {
        "args" => excess_args.map { |arg| context.evaluate(arg) },
        "kwargs" => excess_kwargs.transform_values! { |val| context.evaluate(val) }
      }

      args.each do |k, v|
        namespace[k] = if v == :undefined
                         context.env.undefined(k, node: params[k])
                       else
                         context.evaluate(v)
                       end
      end

      macro_context = context.copy(
        namespace,
        disabled_tags: DISABLED_TAGS,
        carry_loop_iterations: true
      )

      block.render(macro_context, buffer)
    end

    def expressions
      [*@args, *@kwargs.map(&:value)]
    end
  end
end
