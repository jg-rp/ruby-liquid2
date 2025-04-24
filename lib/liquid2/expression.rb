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
  end
end
