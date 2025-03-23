# frozen_string_literal: true

require_relative "../ast"

module Liquid2
  class Other < Node
    # @param tokens [Array<Token>]
    # @param children [Array<Node>]
    # @param text [String]
    def initialize(tokens, children, text)
      super(tokens, children)
      @text = text
      @blank = text.blank? || text.match?(/\A\s+\Z/)
    end

    def render(_context, buffer)
      buffer.write(@text)
    end
  end
end
