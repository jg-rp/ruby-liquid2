# frozen_string_literal: true

module Liquid2
  # The base class for all Liquid errors.
  class LiquidError < StandardError
    attr_accessor :node_or_token, :template_name

    def initialize(message, node_or_token = nil)
      super(message)
      @node_or_token = node_or_token
      @template_name = nil
    end

    # TODO: detailed_message
    # TODO: full_message
  end

  class LiquidSyntaxError < LiquidError; end
  class LiquidArgumentError < LiquidError; end
  class LiquidTypeError < LiquidError; end
  class LiquidTemplateNotFoundError < LiquidError; end
  class LiquidFilterNotFoundError < LiquidError; end
  class LiquidResourceLimitError < LiquidError; end
  class UndefinedError < LiquidError; end
end
