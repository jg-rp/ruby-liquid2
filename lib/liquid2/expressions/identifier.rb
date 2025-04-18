# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  class Identifier < Expression
    attr_reader :name

    # Try to cast _expr_ to an Identifier.
    # @param expr [Expression]
    def self.from(expr, trailing_question: true)
      # XXX:
      raise "TODO"
    end

    # @param token [[Symbol, String?, Integer]]
    def initialize(token)
      super
      @name = token[1]
    end

    def evaluate(_context)
      @name
    end
  end
end
