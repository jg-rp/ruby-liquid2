# frozen_string_literal: true

require_relative "parser"
require_relative "template"
require_relative "nodes/tags/assign"

module Liquid2
  class Environment
    attr_reader :mode, :tags, :local_namespace_limit

    def initialize
      # A mapping of tag names to objects responding to
      # `parse: (TokenStream, Parser) -> Tag`
      @tags = { "assign" => AssignTag }
      @parser = Parser.new(self)
      @mode = :lax

      @local_namespace_limit = nil
      @context_depth_limit = 30
    end

    # @param source [String] template source text.
    # @return [Template]
    def parse(source)
      Template.new(self, @parser.parse(source))
    end
  end
end
