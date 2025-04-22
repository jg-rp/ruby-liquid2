# frozen_string_literal: true

require_relative "parser"
require_relative "template"
require_relative "undefined"
require_relative "loader"
require_relative "filters/date"
require_relative "filters/default"
require_relative "filters/filter"
require_relative "filters/find"
require_relative "filters/math"
require_relative "filters/array"
require_relative "filters/size"
require_relative "filters/slice"
require_relative "filters/sort"
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
                :default_trim, :validate_filter_arguments

    def initialize(loader: nil, mode: :lax, globals: nil)
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

      @mode = mode
      @auto_escape = false

      @local_namespace_limit = nil
      @context_depth_limit = 30
      @loop_iteration_limit = nil
      @output_stream_limit = nil

      @suppress_blank_control_flow_blocks = true

      @validate_filter_arguments = true

      @default_trim = :whitespace_control_plus

      @undefined = Undefined

      @loader = loader || HashLoader.new({})

      @globals = globals || {} # steep:ignore

      @scanner = StringScanner.new("")

      setup_tags_and_filters
    end

    # @param source [String] template source text.
    # @return [Template]
    def parse(source, name: "", path: nil, up_to_date: nil, globals: nil, overlay: nil)
      Template.new(self,
                   Parser.parse(self, source, scanner: @scanner),
                   name: name, path: path, up_to_date: up_to_date,
                   globals: make_globals(globals), overlay: overlay)
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
      register_filter("abs", Liquid2::Filters.method(:abs))
      register_filter("append", Liquid2::Filters.method(:append))
      register_filter("at_least", Liquid2::Filters.method(:at_least))
      register_filter("at_most", Liquid2::Filters.method(:at_most))
      register_filter("capitalize", Liquid2::Filters.method(:capitalize))
      register_filter("ceil", Liquid2::Filters.method(:ceil))
      register_filter("compact", Liquid2::Filters::Compact.new)
      register_filter("concat", Liquid2::Filters.method(:concat))
      register_filter("date", Liquid2::Filters.method(:date))
      register_filter("default", Liquid2::Filters.method(:default))
      register_filter("divided_by", Liquid2::Filters.method(:divided_by))
      register_filter("downcase", Liquid2::Filters.method(:downcase))
      register_filter("escape_once", Liquid2::Filters.method(:escape_once))
      register_filter("escape", Liquid2::Filters.method(:escape))
      register_filter("find_index", Liquid2::Filters::FindIndex.new)
      register_filter("find", Liquid2::Filters::Find.new)
      register_filter("first", Liquid2::Filters.method(:first))
      register_filter("floor", Liquid2::Filters.method(:floor))
      register_filter("has", Liquid2::Filters::Has.new)
      register_filter("join", Liquid2::Filters.method(:join))
      register_filter("last", Liquid2::Filters.method(:last))
      register_filter("lstrip", Liquid2::Filters.method(:lstrip))
      register_filter("map", Liquid2::Filters::Map.new)
      register_filter("minus", Liquid2::Filters.method(:minus))
      register_filter("modulo", Liquid2::Filters.method(:modulo))
      register_filter("newline_to_br", Liquid2::Filters.method(:newline_to_br))
      register_filter("plus", Liquid2::Filters.method(:plus))
      register_filter("prepend", Liquid2::Filters.method(:prepend))
      register_filter("reject", Liquid2::Filters::Reject.new)
      register_filter("remove_first", Liquid2::Filters.method(:remove_first))
      register_filter("remove_last", Liquid2::Filters.method(:remove_last))
      register_filter("remove", Liquid2::Filters.method(:remove))
      register_filter("replace_first", Liquid2::Filters.method(:replace_first))
      register_filter("replace_last", Liquid2::Filters.method(:replace_last))
      register_filter("replace", Liquid2::Filters.method(:replace))
      register_filter("reverse", Liquid2::Filters.method(:reverse))
      register_filter("round", Liquid2::Filters.method(:round))
      register_filter("rstrip", Liquid2::Filters.method(:rstrip))
      register_filter("size", Liquid2::Filters.method(:size))
      register_filter("slice", Liquid2::Filters.method(:slice))
      register_filter("sort_natural", Liquid2::Filters::SortNatural.new)
      register_filter("sort", Liquid2::Filters::Sort.new)
      register_filter("split", Liquid2::Filters.method(:split))
      register_filter("strip_html", Liquid2::Filters.method(:strip_html))
      register_filter("strip_newlines", Liquid2::Filters.method(:strip_newlines))
      register_filter("strip", Liquid2::Filters.method(:strip))
      register_filter("sum", Liquid2::Filters::Sum.new)
      register_filter("times", Liquid2::Filters.method(:times))
      register_filter("upcase", Liquid2::Filters.method(:upcase))
      register_filter("where", Liquid2::Filters::Where.new)
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

    # Merge environment globals with another namespace.
    def make_globals(namespace)
      namespace.nil? ? @globals : @globals.merge(namespace)
    end
  end
end
