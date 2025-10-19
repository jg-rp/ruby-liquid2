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
      @items.to_h { |item| context.evaluate(item) }
    end

    def children = @items
  end

  # A key/value pair belonging to an object literal.
  class ObjectLiteralItem < Expression
    attr_reader :value, :name, :sym

    # @param name [String]
    # @param value [Expression]
    def initialize(token, name, value)
      super(token)
      @name = name
      @sym = name.to_sym
      @value = value
    end

    def evaluate(context)
      [@name, context.evaluate(@value)]
    end

    def children = [@value]
  end
end
