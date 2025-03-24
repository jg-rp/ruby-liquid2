# frozen_string_literal: true

require_relative "../node"

module Liquid2
  class Other < Node
    # @param children [Array<Node | Token>]
    # @param text [String]
    def initialize(children, text)
      super(children)
      @text = text
      @blank = text.blank? || text.match?(/\A\s+\Z/)
    end

    def render(_context, buffer)
      buffer.write(@text)
    end
  end
end
