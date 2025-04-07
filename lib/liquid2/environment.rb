# frozen_string_literal: true

require_relative "parser"
require_relative "template"
require_relative "undefined"
require_relative "loader"
require_relative "filters/math"
require_relative "filters/array"
require_relative "filters/slice"
require_relative "filters/string"
require_relative "nodes/tags/assign"
require_relative "nodes/tags/if"
require_relative "nodes/tags/for"
require_relative "nodes/tags/liquid"
require_relative "nodes/tags/echo"
require_relative "nodes/tags/capture"
require_relative "nodes/tags/case"
require_relative "nodes/tags/cycle"
require_relative "nodes/tags/decrement"
require_relative "nodes/tags/increment"
require_relative "nodes/tags/include"
require_relative "nodes/tags/raw"
require_relative "nodes/tags/unless"
require_relative "nodes/tags/block_comment"
require_relative "nodes/tags/inline_comment"
require_relative "nodes/tags/render"

module Liquid2
  # Template parsing and rendering configuration.
  #
  # A Liquid::Environment is where you might register custom tags and filters,
  # or store global context data that should be available to all templates.
  class Environment
    attr_reader :mode, :tags, :local_namespace_limit, :context_depth_limit, :loop_iteration_limit,
                :output_stream_limit, :filters, :auto_escape, :suppress_blank_control_flow_blocks,
                :default_trim

    def initialize(loader: nil, mode: :lax)
      # A mapping of tag names to objects responding to `parse`.
      @tags = {
        "assign" => AssignTag,
        "if" => IfTag,
        "for" => ForTag,
        "break" => BreakTag,
        "continue" => ContinueTag,
        "liquid" => LiquidTag,
        "echo" => EchoTag,
        "capture" => CaptureTag,
        "cycle" => CycleTag,
        "decrement" => DecrementTag,
        "increment" => IncrementTag,
        "raw" => RawTag,
        "unless" => UnlessTag,
        "case" => CaseTag,
        "include" => IncludeTag,
        "comment" => BlockComment,
        "#" => InlineComment,
        "render" => RenderTag
      }

      # A mapping of filter names to objects responding to `#call(left, ...)`,
      # along with a flag to indicate if the callable accepts a `context`
      # keyword argument.
      @filters = {}

      @parser = Parser.new(self)
      @mode = mode
      @auto_escape = false

      @local_namespace_limit = nil
      @context_depth_limit = 30
      @loop_iteration_limit = nil
      @output_stream_limit = nil

      @suppress_blank_control_flow_blocks = false

      @default_trim = :whitespace_control_plus

      @undefined = Undefined

      @loader = loader || HashLoader.new({})

      setup_tags_and_filters
    end

    # @param source [String] template source text.
    # @return [Template]
    def parse(source, name: "", path: nil, up_to_date: nil, globals: nil, overlay: nil)
      Template.new(self,
                   @parser.parse(source),
                   name: name, path: path, up_to_date: up_to_date,
                   globals: globals, overlay: overlay)
    end

    # Add or replace a filter. The same callable can be registered multiple times with
    # different names.
    #
    # If _callable_ accepts a keyword parameter called `context`, the active render
    # context will be passed to `#call`.
    #
    # @param name [String] The name of the filter, as used by template authors.
    # @param callable [responds to call] An object that responds to `#call(left, ...)`
    #   and `#parameters`. Like a Proc or Method.
    def register_filter(name, callable)
      # TODO: optional filter argument validation
      with_context = callable.parameters.index do |(kind, param)|
        kind == :keyreq && param == :context
      end
      @filters[name] = [callable, with_context]
    end

    # Remove a filter from the filter register.
    # @param name [String] The name of the filter.
    # @return [callable | nil] The callable implementing the removed filter, or nil
    #    if _name_ did not exist in the filter register.
    def delete_filter(name)
      @filters.delete(name)
    end

    def setup_tags_and_filters
      register_filter("upcase", ->(left) { Liquid2.to_s(left).upcase })
      register_filter("downcase", ->(left) { Liquid2.to_s(left).downcase })
      register_filter("slice", SliceFilter.new)
      register_filter("split", ->(left, sep) { Liquid2.to_s(left).split(Liquid2.to_s(sep)) })
      register_filter("join", Liquid2::Filters.method(:join))
      register_filter("abs", Liquid2::Filters.method(:abs))
      register_filter("at_least", Liquid2::Filters.method(:at_least))
      register_filter("at_most", Liquid2::Filters.method(:at_most))
      register_filter("append", Liquid2::Filters.method(:append))
      register_filter("capitalize", Liquid2::Filters.method(:capitalize))
      register_filter("ceil", Liquid2::Filters.method(:ceil))
      register_filter("compact", Liquid2::Filters.method(:compact))
      register_filter("first", Liquid2::Filters.method(:first))
    end

    def undefined(name, node: nil)
      @undefined.new(name, node: node)
    end

    def trim(text, left_trim, right_trim)
      left_trim = @default_trim if left_trim == :whitespace_control_default
      right_trim = @default_trim if right_trim == :whitespace_control_default

      if left_trim == right_trim
        return text.strip if left_trim == :whitespace_control_minus
        return text.gsub(/\A[\r\n]+|[\r\n]+\Z/, "") if left_trim == :whitespace_control_tilde

        return text
      end

      if left_trim == :whitespace_control_minus
        text = text.lstrip
      elsif left_trim == :whitespace_control_tilde
        text = text.gsub(/\A[\r\n]+/, "")
      end

      if right_trim == :whitespace_control_minus
        text = text.rstrip
      elsif right_trim == :whitespace_control_tilde
        text = text.gsub(/[\r\n]+\Z/, "")
      end

      text
    end

    # Load and parse a template using the configured template loader.
    # @param name [String] The template's name.
    # @param globals [_Namespace?] Render context variables to attach to the template.
    # @param context [RenderContext?] An optional render context that can be used to
    #   narrow the template search space.
    # @param kwargs Arbitrary arguments that can be used to narrow the template search
    #   space.
    # @return [Template]
    def get_template(name, globals: nil, context: nil, **kwargs)
      @loader.load(self, name, globals: globals, context: context, **kwargs)
    rescue LiquidError => e
      e.template_name = name unless e.template_name
      raise e
    end
  end
end
