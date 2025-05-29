# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # A lambda expression aka arrow function
  class Lambda < Expression
    attr_reader :params, :expr

    # @param params [Array<Identifier>]
    # @param expr [Expression]
    def initialize(token, params, expr)
      super(token)
      @params = params
      @expr = expr
    end

    def evaluate(_context) = self

    def children = [@expr]

    # TODO: scope

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
            rv << context.evaluate(@expr)
          end
        end
      else
        name_param = @params.first.name
        index_param = @params[1].name
        context.extend(scope) do
          enum.each_with_index do |item, index|
            scope[index_param] = index
            scope[name_param] = item
            rv << context.evaluate(@expr)
          end
        end
      end

      rv
    end
  end
end
