# frozen_string_literal: true

require_relative "utils/string_io"

module Liquid2
  # A compiled template bound to a Liquid environment and ready to be rendered.
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

    def render(globals = nil)
      buf = @env.output_stream_limit ? LimitedStringIO.new(@env.output_stream_limit || raise) : StringIO.new
      context = RenderContext.new(self, globals: globals)
      render_with_context(context, buf)
      buf.string
    end

    def render_with_context(context, buffer, partial: false, block_scope: false, namespace: nil)
      bytes = 0

      # TODO: don't extend if namespace is nil
      context.extend(namespace || {}) do
        @ast.children.each do |node|
          if (interrupt = context.interrupts.pop)
            # steep:ignore:start
            raise LiquidSyntaxError.new("unexpected #{interrupt}", node) if !partial && block_scope

            # steep:ignore:end

            context.interrupts << interrupt
          end
          bytes += node.render(context, buffer) # steep:ignore
        end
      end

      bytes
    end
  end
end
