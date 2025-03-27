# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class Lambda < Expression
    # @param children [Array<Token>]
    # @param params [Array<Identifier>]
    # @param expr [Expression]
    def initialize(children, params, expr)
      super(children)
      @params = params
      @expr = expr
    end
  end
end
