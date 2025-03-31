# frozen_string_literal: true

require_relative "../node"

module Liquid2
  class Comment < Node
    attr_reader :wc

    # @param children [Array<Node | Token>]
    # @param text [String]
    def initialize(children, text)
      super(children)
      @text = text
      @wc = @children.map do |child|
        WC_MAP.fetch(child.text) if child.is_a?(Token) && child.kind == :token_whitespace_control
      end.compact
    end

    def render(_context, _buffer) = 0
  end
end
