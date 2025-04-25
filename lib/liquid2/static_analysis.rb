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
          @segments == other.segments
      end

      alias eql? ==

      def hash
        @segments.hash
      end

      protected

      def segments_to_s(segments)
        segments.map do |segment|
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
      raise "TODO"
    end

    def self.extract_filters(expression, template_name)
      raise "TODO"
    end

    def self.analyze_variables(expression, template_name, scope, globals, variables)
      raise "TODO"
    end

    def self.segments(path, template_name)
      raise "TODO"
    end
  end
end
