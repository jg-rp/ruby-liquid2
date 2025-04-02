# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # A lambda expression aka arrow function
  class Lambda < Expression
    # @param children [Array<Token>]
    # @param params [Array<Identifier>]
    # @param expr [Expression]
    def initialize(children, params, expr)
      super(children)
      @params = params
      @expr = expr
    end

    def evaluate(_context) = nil

    # Apply this lambda function to elements from _enum_.
    # @param context [RenderContext]
    # @param enum [Enumerable<Object>]
    # @return [Enumerable<Object>]
    def map(context, enum)
      scope = {} # : Hash[String, untyped]
      rv = [] # : Array[untyped]

      if @params.length == 1
        param = @params.first.name
        context.extend(scope) do
          enum.each do |item|
            scope[param] = item
            rv << @expr.evaluate(context)
          end
        end
      else
        name_param = @params.first.name
        index_param = @params[1].name
        context.extend(scope) do
          enum.each_with_index do |item, index|
            scope[index_param] = index
            scope[name_param] = item
            rv << @expr.evaluate(context)
          end
        end
      end

      rv
    end
  end
end
