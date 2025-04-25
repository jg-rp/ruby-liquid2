# frozen_string_literal: true

module Liquid2
  # Base class for all expressions.
  class Expression
    attr_reader :token

    # @param token [[Symbol, String?, Integer]]
    def initialize(token)
      @token = token
    end

    # Return children of this expression.
    def children = []

    # Return variables this expression adds to the scope of any child expressions.
    # Currently used by lambda expressions only.
    def scope = nil
  end
end
