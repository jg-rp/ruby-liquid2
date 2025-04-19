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
      @filters.each { |f| left = f.evaluate(left, context) }
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
        @filters.each { |f| rv = f.evaluate(rv, context) }
      end

      @tail_filters.each { |f| rv = f.evaluate(rv, context) }
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
      filter.call(left, *positional_args, **keyword_args) # steep:ignore
    rescue ArgumentError => e
      raise LiquidArgumentError.new(e.message, @token)
    end

    private

    # @param context [RenderContext]
    # @return [positional arguments, keyword arguments] An array with two elements.
    #   The first is an array of evaluates positional arguments. The second is a hash
    #   of keyword names to evaluated keyword values.
    def evaluate_args(context)
      positional_args = [] # @type var positional_args: Array[untyped]
      keyword_args = {} # @type var keyword_args: Hash[Symbol, untyped]

      @args.each do |arg|
        if arg.respond_to?(:name)
          keyword_args[arg.name] = context.evaluate(arg.value)
        else
          positional_args << context.evaluate(arg)
        end
      end

      [positional_args, keyword_args]
    end
  end
end
