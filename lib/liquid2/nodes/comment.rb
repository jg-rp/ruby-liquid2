# frozen_string_literal: true

require_relative "../node"

module Liquid2
  # `{# comment #}` style comments.
  class Comment < Node
    attr_reader :text

    # @param text [String]
    def initialize(token, text)
      super(token)
      @text = text
    end

    def render(_context, _buffer) = 0
  end
end
