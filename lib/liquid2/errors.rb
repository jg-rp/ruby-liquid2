# frozen_string_literal: true

module Liquid2
  # The base class for all Liquid errors.
  class LiquidError < StandardError
    def initialize(message, token)
      super(message)
      @token = token
    end

    # TODO: detailed_message
    # TODO: full_message
  end

  class LiquidSyntaxError < LiquidError; end
  class UndefinedError < LiquidError; end
end
