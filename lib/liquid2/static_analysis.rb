# frozen_string_literal: true

module Liquid2
  # Template static analysis.
  module StaticAnalysis
    # The location of a variable, tag or filter.
    class Span
      attr_reader :template_name, :index

      def initialize(template_name, index)
        @template_name = template_name
        @index = index
      end

      # @param source [String] Template source text.
      # @return [[Integer, Integer]] The line and column number of this span in _source_.
      def line_col(source)
        lines = source.lines
        cumulative_length = 0
        target_line_index = -1

        lines.each_with_index do |line, i|
          cumulative_length += line.length
          next unless @index < cumulative_length

          target_line_index = i
          line_number = target_line_index + 1
          column_number = @index - (cumulative_length - lines[target_line_index].length)
          return [line_number, column_number]
        end

        raise "index is out of bounds for span"
      end

      def ==(other)
        self.class == other.class &&
          @template_name == other.template_name &&
          @index == other.index
      end

      alias eql? ==

      def hash
        [@template_name, @index].hash
      end
    end

    # A variable as a sequence of segments and its location.
    class Variable
      attr_reader :segments, :span

      RE_PROPERTY = /\A[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*\Z/

      def initialize(segments, span)
        @segments = segments
        @span = span
      end

      def to_s
        segments_to_s(@segments)
      end

      def ==(other)
        self.class == other.class &&
          @segments == other.segments &&
          @span == other.span
      end

      alias eql? ==

      def hash
        @segments.hash
      end

      protected

      def segments_to_s(segments)
        head, *rest = segments

        head.to_s + rest.map do |segment|
          case segment
          when Array
            "[#{segments_to_s(segment)}]"
          when String
            if segment.match?(RE_PROPERTY)
              ".#{segment}"
            else
              "[#{segment.inspect}]"
            end
          else
            "[#{segment}]"
          end
        end.join
      end
    end

    # Helper to manage variable scope during static analysis.
    class StaticScope
      def initialize(globals)
        @stack = [globals]
      end

      def include?(key)
        @stack.any? { |scope| scope.include?(key) }
      end

      def push(scope)
        @stack << scope
        self
      end

      def pop
        @stack.pop
      end

      def add(name)
        @stack.first.add(name)
      end
    end

    # Helper to group variables by their root segment during static analysis.
    class VariableMap
      attr_reader :data

      def initialize
        @data = {}
      end

      def [](var)
        key = var.segments.first.to_s
        @data[key] = [] unless @data.include?(key)
        @data[key]
      end

      def add(var)
        send(:[], var) << var
      end
    end

    # The result of analyzing a template.
    class Result
      attr_reader :variables, :globals, :locals, :filters, :tags

      def initialize(variables, globals, locals, filters, tags)
        @variables = variables
        @globals = globals
        @locals = locals
        @filters = filters
        @tags = tags
      end
    end

    def self.analyze(template, include_partials:)
      variables = VariableMap.new
      globals = VariableMap.new
      locals = VariableMap.new

      # @type var filters: Hash[String, Array[Span]]
      filters = Hash.new { |hash, key| hash[key] = [] }
      # @type var tags: Hash[String, Array[Span]]
      tags = Hash.new { |hash, key| hash[key] = [] }

      # @type var template_scope: Set[String]
      template_scope = Set[]
      root_scope = StaticScope.new(template_scope)
      static_context = Liquid2::RenderContext.new(template)

      # Names of partial templates that have already been analyzed.
      # @type var seen: Set[String]
      seen = Set[]

      # @type var visit: ^(Node, String, StaticScope) -> void
      visit = lambda do |node, template_name, scope|
        seen.add(template_name) unless template_name.empty?

        # Update tags
        tags[node.name] << Span.new(template_name, node.token.last) if node.is_a?(Liquid2::Tag)

        # Update variables from node.expressions
        node.expressions.each do |expr|
          if expr.is_a?(Liquid2::Expression)
            analyze_variables(expr, template_name, scope, globals,
                              variables)
          end

          # Update filters from expr
          extract_filters(expr, template_name).each do |name, span|
            filters[name] << span
          end
        end

        # Update template scope from node.template_scope
        node.template_scope.each do |ident|
          scope.add(ident.name)
          locals.add(Variable.new([ident.name], Span.new(template_name, ident.token.last)))
        end

        if (partial = node.partial_scope)
          partial_name = static_context.evaluate(partial.name).to_s

          unless seen.include?(partial_name)
            partial_scope = if partial.scope == :isolated
                              StaticScope.new(Set.new(partial.in_scope.map(&:name)))
                            else
                              root_scope.push(Set.new(partial.in_scope.map(&:name)))
                            end

            node.children(static_context, include_partials: include_partials).each do |child|
              seen.add(partial_name)
              visit.call(child, partial_name, partial_scope) if child.is_a?(Liquid2::Node)
            end

            partial_scope.pop
          end
        else
          scope.push(Set.new(node.block_scope.map(&:name)))
          node.children(static_context, include_partials: include_partials).each do |child|
            visit.call(child, template_name, scope) if child.is_a?(Liquid2::Node)
          end
          scope.pop
        end
      end

      template.ast.each do |node|
        visit.call(node, template.name, root_scope) if node.is_a?(Liquid2::Node)
      end

      Result.new(variables.data, globals.data, locals.data, filters, tags)
    end

    def self.extract_filters(expression, template_name)
      filters = [] # : Array[[String, Span]]

      if expression.is_a?(Liquid2::FilteredExpression) && !expression.filters.nil?
        expression.filters.each do |filter|
          filters << [filter.name, Span.new(template_name, filter.token.last)]
        end
      elsif expression.is_a?(Liquid2::TernaryExpression)
        expression.filters.each do |filter|
          filters << [filter.name, Span.new(template_name, filter.token.last)]
        end

        expression.tail_filters.each do |filter|
          filters << [filter.name, Span.new(template_name, filter.token.last)]
        end
      end

      if expression.is_a?(Liquid2::Expression)
        expression.children.each do |expr|
          filters.concat(extract_filters(expr, template_name))
        end
      end

      filters
    end

    def self.analyze_variables(expression, template_name, scope, globals, variables)
      if expression.is_a?(Path)
        var = Variable.new(segments(expression, template_name),
                           Span.new(template_name, expression.token.last))
        variables.add(var)

        root = var.segments.first.to_s
        globals.add(var) unless scope.include?(root)
      end

      if (child_scope = expression.scope)
        scope.push(Set.new(child_scope.map(&:name)))
        expression.children.each do |expr|
          if expr.is_a?(Expression)
            analyze_variables(expr, template_name, scope, globals,
                              variables)
          end
        end
        scope.pop
      else
        expression.children.each do |expr|
          if expr.is_a?(Expression)
            analyze_variables(expr, template_name, scope, globals,
                              variables)
          end
        end
      end
    end

    def self.segments(path, template_name)
      # @type var segments_: Array[untyped]
      segments_ = [path.head.is_a?(Path) ? segments(path.head, template_name) : path.head]

      path.segments.each do |segment|
        segments_ << if segment.is_a?(Path)
                       segments(segment, template_name)
                     else
                       segment
                     end
      end

      segments_
    end
  end
end
