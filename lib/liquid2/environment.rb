# frozen_string_literal: true

module Liquid2
  class Environment
    def initialize
      # A mapping of tag names to objects responding to
      # `parse: (TokenStream, Parser) -> Tag`
      @tags = {}
    end
  end
end
