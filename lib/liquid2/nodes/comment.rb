# frozen_string_literal: true

require_relative "../node"

module Liquid2
  # `{# comment #}` style comments.
  class Comment < Node
    attr_reader :wc

    # @param children [Array<Node | Token>]
    # @param comment [Token]
    def initialize(children, token)
      super(children)
      @text = token.text
      @wc = @children.map do |child|
        WC_MAP.fetch(child.text) if child.is_a?(Token) && child.kind == :token_whitespace_control
      end.compact
    end

    def render(_context, _buffer) = 0
  end
end
