# frozen_string_literal: true

module Liquid2
  class Template
    attr_reader :ast

    # @param ast [RootNode]
    def initialize(ast)
      @ast = ast
    end

    def to_s = @ast.to_s

    def dump = @ast.dump
  end
end
