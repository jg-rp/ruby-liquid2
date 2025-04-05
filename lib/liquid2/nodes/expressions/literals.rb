# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # Base class for expression literals.
  class Literal < Expression
    # @param token [Token]
    def initialize(token)
      super([token])
    end
  end

  # Literal true
  class TrueLiteral < Literal
    def evaluate(_context) = true
  end

  # Literal false
  class FalseLiteral < Literal
    def evaluate(_context) = false
  end

  # Literal nil
  class NilLiteral < Literal
    def evaluate(_context) = nil
  end

  # Integer literal
  class IntegerLiteral < Literal
    # @param token [Token]
    def initialize(token)
      super
      @value = Liquid2.to_i(token.text)
    end

    def evaluate(_context) = @value
  end

  # Float literal
  class FloatLiteral < Literal
    # @param token [Token]
    def initialize(token)
      super
      @value = token.text.to_f
    end

    def evaluate(_context) = @value
  end
end
