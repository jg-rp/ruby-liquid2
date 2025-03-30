# frozen_string_literal: true

require_relative "../node"

module Liquid2
  class Lambda < Node
    # @param children [Array<Token>]
    # @param params [Array<Identifier>]
    # @param expr [Expression]
    def initialize(children, params, expr)
      super(children)
      @params = params
      @expr = expr
    end

    # Apply this lambda function to elements from _enum_.
    # @param context [RenderContext]
    # @param enum [Enumerable<Object>]
    # @return [Enumerable<Object>]
    def map(context, enum)
      scope = {}
      rv = []

      if @params.length == 1
        param = @params.first.name
        context.extend(scope) do
          enum.each do |item|
            scope[param] = item
            rv << @expr.evaluate(context)
          end
        end
      else
        name_param, index_param = @params[...2].map(&:name)
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
