# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _case_ tag.
  class CaseTag < Tag
    def self.parse(stream, parser)
    end

    def initialize(children, expression, whens, default)
      super(children)
      @expression = expression
      @whens = whens
      @default = default
      @blank = whens.map(&:blank).all? && (!default || default.blank)
    end

    def render(context, buffer)
    end
  end
end
