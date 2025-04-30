# frozen_string_literal: true

module Liquid2
  # A compiled template bound to a Liquid environment and ready to be rendered.
  class Template
    attr_reader :env, :ast, :name, :path, :globals, :overlay, :up_to_date

    # @param env [Environment]
    # @param source [String]
    # @param ast [Array[Node | String]]
    # @param name [String] The template's name.
    # @param path [String?] The path or other qualifying data to _name_.
    # @param globals [_Namespace] Global template variables.
    # @param overlay [_Namespace] Additional template variables. Could be from front matter
    #   or other meta data store, for example.
    def initialize(env, source, ast, name: "", path: nil, up_to_date: nil, globals: nil,
                   overlay: nil)
      @env = env
      @source = source
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

    def render(globals = nil)
      buf = +""
      context = RenderContext.new(self, globals: make_globals(globals))
      render_with_context(context, buf)
      buf
    end

    def analyze(include_partials: false)
      Liquid2::StaticAnalysis.analyze(self, include_partials: include_partials)
    end

    def render_with_context(context, buffer, partial: false, block_scope: false, namespace: nil)
      # TODO: don't extend if namespace is nil
      context.extend(namespace || {}) do
        index = 0
        while (node = @ast[index])
          index += 1
          case node
          when String
            buffer << node
          else
            node.render_with_disabled_tag_check(context, buffer)
          end

          next unless (interrupt = context.interrupts.pop)

          if !partial || block_scope
            raise LiquidSyntaxError.new("unexpected #{interrupt}",
                                        node.token) # steep:ignore
          end

          context.interrupts << interrupt
          break
        end
      end
    rescue LiquidError => e
      e.source = @source
      e.template_name = @name unless @name.empty?
      raise
    end

    # Merge template globals with another namespace.
    def make_globals(namespace)
      namespace.nil? ? @globals : @globals.merge(namespace)
    end

    def up_to_date?
      @up_to_date&.call
    end

    def comments
      context = RenderContext.new(self)
      nodes = [] # : Array[BlockComment | InlineComment | Comment]

      # @type var visit: ^(Node) -> void
      visit = lambda do |node|
        if node.is_a?(BlockComment) || node.is_a?(InlineComment) || node.is_a?(Comment)
          nodes << node
        end

        node.children(context, include_partials: false).each do |child|
          visit.call(child) if child.is_a?(Node)
        end
      end

      @ast.each { |node| visit.call(node) if node.is_a?(Node) }

      nodes
    end
  end
end
