# frozen_string_literal: true

require_relative "utils/string_io"

module Liquid2
  # A compiled template bound to a Liquid environment and ready to be rendered.
  class Template
    attr_reader :env, :ast, :name, :path, :globals, :overlay, :up_to_date

    # @param env [Environment]
    # @param ast [RootNode]
    # @param name [String] The template's name.
    # @param path [String?] The path or other qualifying data to _name_.
    # @param globals [_Namespace] Global template variables.
    # @param overlay [_Namespace] Additional template variables. Could be from front matter
    #   or other meta data store, for example.
    def initialize(env, ast, name: "", path: nil, up_to_date: nil, globals: nil, overlay: nil)
      @env = env
      @ast = ast
      @name = name
      @path = path
      @globals = globals || {} # steep:ignore UnannotatedEmptyCollection
      @overlay = overlay || {} # steep:ignore UnannotatedEmptyCollection
      @up_to_date = up_to_date
    end

    def to_s = @ast.to_s

    # Return this template's path joined with its name, or just name if path is not available.
    def full_name
      @name + @path.to_s
    end

    def dump = @ast.dump

    def render(globals = nil)
      buf = @env.output_stream_limit ? LimitedStringIO.new(@env.output_stream_limit || raise) : StringIO.new
      context = RenderContext.new(self, globals: make_globals(globals))
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

    # Merge templates globals with another namespace.
    def make_globals(namespace)
      namespace.nil? ? @globals : @globals.merge(namespace)
    end
  end
end
