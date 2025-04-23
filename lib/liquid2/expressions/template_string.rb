# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # Quoted string with interpolated expressions.
  class TemplateString < Expression
    # @param segments [Array<Expression>]
    def initialize(token, segments)
      super(token)
      @segments = segments
    end

    def evaluate(context)
      @segments.map { |expr| Liquid2.to_s(context.evaluate(expr)) }.join
    end
  end
end
