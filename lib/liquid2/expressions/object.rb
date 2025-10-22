# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # JavaScript-style object/hash literal
  class ObjectLiteral < Expression
    # @param items [Array<ObjectLiteralItem>]
    def initialize(token, items)
      super(token)
      @items = items
    end

    def evaluate(context)
      result = {} # : Hash[String,untyped]
      @items.each do |item|
        key, value = context.evaluate(item)
        if item.spread
          if value.is_a?(Hash)
            result.merge!(value)
          elsif value.respond_to?(:to_h)
            result.merge!(value.to_h)
          end
        else
          result[key] = value
        end
      end
      result
    end

    def children = @items
  end

  # A key/value pair belonging to an object literal.
  class ObjectLiteralItem < Expression
    attr_reader :value, :name, :sym, :spread

    # @param name [String]
    # @param value [Expression]
    def initialize(token, name, value, spread: false)
      super(token)
      @name = name
      @sym = name.to_sym
      @value = value
      @spread = spread
    end

    def evaluate(context)
      [@name, context.evaluate(@value)]
    end

    def children = [@value]
  end
end
