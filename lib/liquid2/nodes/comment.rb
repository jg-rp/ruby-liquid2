# frozen_string_literal: true

require_relative "../node"

module Liquid2
  class Comment < Node
    # @param children [Array<Node | Token>]
    # @param text [String]
    def initialize(children, text)
      super(children)
      @text = text
    end

    def render(_context, _buffer) = 0
  end
end
