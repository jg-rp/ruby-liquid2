# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # A primary expression with optional filters.
  class FilteredExpression < Expression
    attr_reader :filters

    def initialize(token, left, filters)
      super(token)
      @left = left
      @filters = filters
    end

    def evaluate(context)
      left = context.evaluate(@left)
      return left if @filters.nil?

      index = 0
      while (filter = (@filters || raise)[index])
        left = filter.evaluate(left, context)
        index += 1
      end
      left
    end

    def children =[@left, *@filters]
  end

  # An inline conditional expression.
  class TernaryExpression < Expression
    attr_reader :filters, :tail_filters

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

    def children
      # @type var nodes: Array[untyped]
      nodes = [@left, @condition]
      nodes << @alternative if @alternative
      nodes.concat(@filters) if @filters
      nodes.concat(@tail_filters) if @tail_filters
      nodes
    end
  end

  # A Liquid filter with a name and array of arguments.
  class Filter < Expression
    attr_reader :name, :args

    # @param name [String]
    # @param args [Array[Expression]?]
    def initialize(token, name, args)
      super(token)
      @name = name
      @args = args
    end

    def evaluate(left, context)
      filter, with_context = context.env.filters[@name]
      raise LiquidFilterNotFoundError.new("unknown filter #{@name.inspect}", @token) unless filter

      return filter.call(left) if @args.nil? && !with_context # steep:ignore
      return filter.call(left, context: context) if @args.nil? && with_context # steep:ignore

      positional_args = [] # @type var positional_args: Array[untyped]
      keyword_args = {} # @type var keyword_args: Hash[Symbol, untyped]

      index = 0
      loop do
        # `@args[index]` could be `false` or `nil`
        break if index >= @args.length # steep:ignore

        arg = @args[index] # steep:ignore
        index += 1
        if arg.respond_to?(:sym)
          keyword_args[arg.sym] = context.evaluate(arg.value)
        else
          positional_args << context.evaluate(arg)
        end
      end

      keyword_args[:context] = context if with_context

      if keyword_args.empty?
        filter.call(left, *positional_args) # steep:ignore
      else
        filter.call(left, *positional_args, **keyword_args) # steep:ignore
      end
    rescue ArgumentError, TypeError => e
      raise LiquidArgumentError.new(e.message, @token)
    end

    def children = @args || []
  end
end
