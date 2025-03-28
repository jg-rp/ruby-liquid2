# frozen_string_literal: true

module Liquid2
  class Template
    attr_reader :env, :ast

    # @param env [Environment]
    # @param ast [RootNode]
    def initialize(env, ast)
      @env = env
      @ast = ast
    end

    def to_s = @ast.to_s

    def dump = @ast.dump
  end
end
