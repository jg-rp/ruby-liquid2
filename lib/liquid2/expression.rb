# frozen_string_literal: true

module Liquid2
  # Base class for all expressions.
  class Expression
    attr_reader :token

    # @param token [[Symbol, String?, Integer]]
    def initialize(token)
      @token = token
    end
  end
end
