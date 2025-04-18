# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  class Identifier < Expression
    attr_reader :name

    # Try to cast _expr_ to an Identifier.
    # @param expr [Expression]
    def self.from(expr, trailing_question: true)
      # XXX:
      unless expr.is_a?(Path) && expr.segments.length == 1
        raise LiquidSyntaxError.new("expected an identifier, found #{expr}", expr)
      end

      val = expr.segments.first.selector

      unless val.to_s.match?(/[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*/)
        raise LiquidSyntaxError.new("invalid identifier", expr)
      end

      token = expr.children.first
      new(token)
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
