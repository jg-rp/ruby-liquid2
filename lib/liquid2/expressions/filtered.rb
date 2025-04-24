# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  class FilteredExpression < Expression
    def initialize(token, left, filters)
      super(token)
      @left = left
      @filters = filters
    end

    def evaluate(context)
      left = context.evaluate(@left)
      index = 0
      while (filter = @filters[index])
        left = filter.evaluate(left, context)
        index += 1
      end
      left
    end
  end

  class TernaryExpression < Expression
    # @param left [FilteredExpression]
    # @param condition [BooleanExpression]
    # @param alternative [Expression | nil]
    # @param filters [Array<Filter>]
    # @param tail_filters [Array<Filter>]
    def initialize(token, left, condition, alternative, filters, tail_filters)
      super(token)
      @left = left
      @condition = condition
      @alternative = alternative
      @filters = filters
      @tail_filters = tail_filters
    end

    def evaluate(context)
      rv = nil

      if @condition.evaluate(context)
        rv = @left.evaluate(context)
      elsif @alternative
        rv = context.evaluate(@alternative)
        index = 0
        while (filter = @filters[index])
          rv = filter.evaluate(rv, context)
          index += 1
        end
      end

      index = 0
      while (filter = @tail_filters[index])
        rv = filter.evaluate(rv, context)
        index += 1
      end
      rv
    end
  end

  class Filter < Expression
    attr_reader :name, :args

    # @param name [String]
    # @param args [Array[Expression]]
    def initialize(token, name, args)
      super(token)
      @name = name
      @args = args
    end

    def evaluate(left, context)
      filter, with_context = context.env.filters[@name]
      raise LiquidFilterNotFoundError.new("unknown filter #{@name.inspect}", @token) unless filter

      positional_args, keyword_args = evaluate_args(context)
      keyword_args[:context] = context if with_context

      if keyword_args.empty?
        filter.call(left, *positional_args) # steep:ignore
      else
        filter.call(left, *positional_args, **keyword_args) # steep:ignore
      end
    rescue ArgumentError, TypeError => e
      raise LiquidArgumentError.new(e.message, @token)
    end

    def children = @args

    private

    # @param context [RenderContext]
    # @return [positional arguments, keyword arguments] An array with two elements.
    #   The first is an array of evaluates positional arguments. The second is a hash
    #   of keyword names to evaluated keyword values.
    def evaluate_args(context)
      positional_args = [] # @type var positional_args: Array[untyped]
      keyword_args = {} # @type var keyword_args: Hash[Symbol, untyped]

      index = 0
      loop do
        # `@args[index]` could be `false` or `nil`
        break if index >= @args.length

        arg = @args[index]
        index += 1
        if arg.respond_to?(:sym)
          keyword_args[arg.sym] = context.evaluate(arg.value)
        else
          positional_args << context.evaluate(arg)
        end
      end

      [positional_args, keyword_args]
    end
  end
end
