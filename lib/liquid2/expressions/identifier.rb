# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  class Identifier < Expression
    attr_reader :name

    # Try to cast _expr_ to an Identifier.
    # @param expr [Expression]
    def self.from(expr, trailing_question: true)
      # TODO: trailing question
      # TODO: expr might not have a token if its not a path.
      unless expr.is_a?(Path) && expr.segments.empty?
        raise LiquidSyntaxError.new("expected an identifier, found #{expr}", expr.token)
      end

      val = expr.head

      unless val.is_a?(String)
        raise LiquidSyntaxError.new("expected an identifier, found #{val}", expr.token)
      end

      # TODO: optimize
      unless val.to_s.match?(/[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*/)
        raise LiquidSyntaxError.new("invalid identifier", expr.token)
      end

      new(expr.token)
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
