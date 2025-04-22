# frozen_string_literal: true

require_relative "if"

module Liquid2
  # The standard _unless_ tag.
  class UnlessTag < IfTag
    END_TAG = "endunless"
    END_BLOCK = Set["else", "elsif", "endunless"].freeze

    def render(context, buffer)
      return @block.render(context, buffer) unless @expression.evaluate(context)

      @alternatives.each do |alt|
        return alt.block.render(context, buffer) if alt.expression.evaluate(context)
      end

      return (@default || raise).render(context, buffer) if @default

      0
    end
  end
end
