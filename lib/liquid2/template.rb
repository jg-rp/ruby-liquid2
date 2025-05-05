# frozen_string_literal: true

module Liquid2
  # A compiled template bound to a Liquid environment and ready to be rendered.
  class Template
    attr_reader :env, :ast, :name, :path, :globals, :overlay, :up_to_date, :source

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

    # Render this template with data from _globals_ added to the render context.
    # @param globals [Hash[::String, untyped]]
    # @return [String]
    def render(globals = nil)
      buf = +""
      context = RenderContext.new(self, globals: make_globals(globals))
      render_with_context(context, buf)
      buf
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

          context.raise_for_output_limit(buffer.bytesize)

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
      # TODO: optimize
      @globals.merge(@overlay || {}, namespace || {})
    end

    # Return `false` if this template is stale and needs to be loaded again.
    # `nil` is returned if an `up_to_date` proc is not available.
    def up_to_date?
      @up_to_date&.call
    end

    # Statically analyze this template and report variable, tag and filter usage.
    # @param include_partials [bool]
    # @return [Liquid2::StaticAnalysis::Result]
    def analyze(include_partials: false)
      Liquid2::StaticAnalysis.analyze(self, include_partials: include_partials)
    end

    # Return an array of comment nodes found in this template.
    #
    # Comment nodes have `token` and `text` attributes. Use `template.comments.map(&:text)`
    # to get an array of comment strings. Each comment string includes leading and trailing
    # whitespace.
    #
    # Note that this method does not try to load included or render templates when looking.
    # for comment nodes.
    #
    # @return [Array[BlockComment | InlineComment | Comment]]
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

    # Return an array of `{% doc %}` nodes found in this template.
    #
    # Each instance of `Liquid2::DocTag` has a `token` and `text` attribute. Use
    # `Template#docs.map(&:text)` to get an array of doc strings.
    #
    # @return [Array[DocTag]]
    def docs
      context = RenderContext.new(self)
      nodes = [] # : Array[DocTag]

      # @type var visit: ^(Node) -> void
      visit = lambda do |node|
        nodes << node if node.is_a?(DocTag)

        node.children(context, include_partials: false).each do |child|
          visit.call(child) if child.is_a?(Node)
        end
      end

      @ast.each { |node| visit.call(node) if node.is_a?(Node) }

      nodes
    end

    # Return arrays of `{% macro %}` and `{% call %}` tags found in this template.
    # @param include_partials [bool]
    # @return [Array[MacroTag], Array[CallTag]]
    def macros(include_partials: false)
      context = RenderContext.new(self)
      macro_nodes = [] # : Array[MacroTag]
      call_nodes = [] # : Array[CallTag]

      # @type var visit: ^(Node) -> void
      visit = lambda do |node|
        macro_nodes << node if node.is_a?(MacroTag)
        call_nodes << node if node.is_a?(CallTag)

        node.children(context, include_partials: include_partials).each do |child|
          visit.call(child) if child.is_a?(Node)
        end
      end

      @ast.each { |node| visit.call(node) if node.is_a?(Node) }

      [macro_nodes, call_nodes]
    end

    # Return an array of variables used in this template, without path segments.
    # @param include_partials [bool]
    # @return [Array[String]]
    def variables(include_partials: false)
      analyze(include_partials: include_partials).variables.keys
    end

    # Return an array of variables used in this template, including path segments.
    # @param include_partials [bool]
    # @return [Array[String]]
    def variable_paths(include_partials: false)
      analyze(include_partials: include_partials).variables.values.flatten.map(&:to_s).uniq
    end

    # Return an array of variables used in this template, each as an array of segments.
    # @param include_partials [bool]
    # @return [Array[Array[String | Integer | Segment]]]
    def variable_segments(include_partials: false)
      analyze(include_partials: include_partials).variables.values.flatten.map(&:segments).uniq
    end

    # Return an array of global variables used in this template, without path segments.
    # @param include_partials [bool]
    # @return [Array[String]]
    def global_variables(include_partials: false)
      analyze(include_partials: include_partials).globals.keys
    end

    # Return an array of global variables used in this template, including path segments.
    # @param include_partials [bool]
    # @return [Array[String]]
    def global_variable_paths(include_partials: false)
      analyze(include_partials: include_partials).globals.values.flatten.map(&:to_s).uniq
    end

    # Return an array of global variables used in this template, each as an array of segments.
    # @param include_partials [bool]
    # @return [Array[Array[String | Integer | Segment]]]
    def global_variable_segments(include_partials: false)
      analyze(include_partials: include_partials).globals.values.flatten.map(&:segments).uniq
    end

    # Return the names of all filters used in this template.
    # @param include_partials [bool]
    # @return [Array[String]]
    def filter_names(include_partials: false)
      analyze(include_partials: include_partials).filters.keys
    end

    # Return the names of all tags used in this template.
    # @param include_partials [bool]
    # @return [Array[String]]
    def tag_names(include_partials: false)
      analyze(include_partials: include_partials).tags.keys
    end
  end
end
