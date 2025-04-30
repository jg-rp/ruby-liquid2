# frozen_string_literal: true

require_relative "loader"
require_relative "parser"
require_relative "template"
require_relative "undefined"
require_relative "filters/array"
require_relative "filters/date"
require_relative "filters/default"
require_relative "filters/math"
require_relative "filters/json"
require_relative "filters/size"
require_relative "filters/slice"
require_relative "filters/sort"
require_relative "filters/string"
require_relative "nodes/tags/assign"
require_relative "nodes/tags/block_comment"
require_relative "nodes/tags/capture"
require_relative "nodes/tags/case"
require_relative "nodes/tags/cycle"
require_relative "nodes/tags/decrement"
require_relative "nodes/tags/doc"
require_relative "nodes/tags/echo"
require_relative "nodes/tags/for"
require_relative "nodes/tags/if"
require_relative "nodes/tags/include"
require_relative "nodes/tags/increment"
require_relative "nodes/tags/inline_comment"
require_relative "nodes/tags/liquid"
require_relative "nodes/tags/raw"
require_relative "nodes/tags/render"
require_relative "nodes/tags/tablerow"
require_relative "nodes/tags/unless"

module Liquid2
  # Template parsing and rendering configuration.
  #
  # A Liquid::Environment is where you might register custom tags and filters,
  # or store global context data that should be available to all templates.
  class Environment
    attr_reader :tags, :local_namespace_limit, :context_depth_limit, :loop_iteration_limit,
                :output_stream_limit, :filters, :suppress_blank_control_flow_blocks,
                :shorthand_indexes

    def initialize(
      context_depth_limit: 30,
      globals: nil,
      loader: nil,
      local_namespace_limit: nil,
      loop_iteration_limit: nil,
      output_stream_limit: nil,
      shorthand_indexes: false,
      suppress_blank_control_flow_blocks: true,
      undefined: Undefined
    )
      # A mapping of tag names to objects responding to `parse(token, parser)`.
      @tags = {}

      # A mapping of filter names to objects responding to `#call(left, ...)`,
      # along with a flag to indicate if the callable accepts a `context`
      # keyword argument.
      @filters = {}

      @context_depth_limit = context_depth_limit
      @globals = globals
      @loader = loader || HashLoader.new({})
      @local_namespace_limit = local_namespace_limit
      @loop_iteration_limit = loop_iteration_limit
      @output_stream_limit = output_stream_limit
      @scanner = StringScanner.new("")
      @shorthand_indexes = shorthand_indexes
      @suppress_blank_control_flow_blocks = suppress_blank_control_flow_blocks
      @undefined = undefined

      setup_tags_and_filters
    end

    # Parse _source_ text as a template.
    # @param source [String] template source text.
    # @return [Template]
    def parse(source, name: "", path: nil, up_to_date: nil, globals: nil, overlay: nil)
      Template.new(self,
                   source,
                   Parser.parse(self, source, scanner: @scanner),
                   name: name, path: path, up_to_date: up_to_date,
                   globals: make_globals(globals), overlay: overlay)
    rescue LiquidError => e
      e.source = source
      e.template_name = name unless name.empty?
      raise
    end

    # Parse and render template source text with _data_ as template variables.
    # @param source [String]
    # @param data [Hash[String, untyped]?]
    # @return [String]
    def render(source, data = nil)
      parse(source).render(data)
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
      @tags["#"] = InlineComment
      @tags["assign"] = AssignTag
      @tags["break"] = BreakTag
      @tags["capture"] = CaptureTag
      @tags["case"] = CaseTag
      @tags["comment"] = BlockComment
      @tags["continue"] = ContinueTag
      @tags["cycle"] = CycleTag
      @tags["decrement"] = DecrementTag
      @tags["doc"] = DocTag
      @tags["echo"] = EchoTag
      @tags["for"] = ForTag
      @tags["if"] = IfTag
      @tags["include"] = IncludeTag
      @tags["increment"] = IncrementTag
      @tags["liquid"] = LiquidTag
      @tags["raw"] = RawTag
      @tags["render"] = RenderTag
      @tags["tablerow"] = TableRowTag
      @tags["unless"] = UnlessTag

      register_filter("abs", Liquid2::Filters.method(:abs))
      register_filter("append", Liquid2::Filters.method(:append))
      register_filter("at_least", Liquid2::Filters.method(:at_least))
      register_filter("at_most", Liquid2::Filters.method(:at_most))
      register_filter("base64_decode", Liquid2::Filters.method(:base64_decode))
      register_filter("base64_encode", Liquid2::Filters.method(:base64_encode))
      register_filter("base64_url_safe_decode", Liquid2::Filters.method(:base64_url_safe_decode))
      register_filter("base64_url_safe_encode", Liquid2::Filters.method(:base64_url_safe_encode))
      register_filter("capitalize", Liquid2::Filters.method(:capitalize))
      register_filter("ceil", Liquid2::Filters.method(:ceil))
      register_filter("compact", Liquid2::Filters.method(:compact))
      register_filter("concat", Liquid2::Filters.method(:concat))
      register_filter("date", Liquid2::Filters.method(:date))
      register_filter("default", Liquid2::Filters.method(:default))
      register_filter("divided_by", Liquid2::Filters.method(:divided_by))
      register_filter("downcase", Liquid2::Filters.method(:downcase))
      register_filter("escape_once", Liquid2::Filters.method(:escape_once))
      register_filter("escape", Liquid2::Filters.method(:escape))
      register_filter("find_index", Liquid2::Filters.method(:find_index))
      register_filter("find", Liquid2::Filters.method(:find))
      register_filter("first", Liquid2::Filters.method(:first))
      register_filter("floor", Liquid2::Filters.method(:floor))
      register_filter("has", Liquid2::Filters.method(:has))
      register_filter("join", Liquid2::Filters.method(:join))
      register_filter("json", Liquid2::Filters.method(:json))
      register_filter("last", Liquid2::Filters.method(:last))
      register_filter("lstrip", Liquid2::Filters.method(:lstrip))
      register_filter("map", Liquid2::Filters.method(:map))
      register_filter("minus", Liquid2::Filters.method(:minus))
      register_filter("modulo", Liquid2::Filters.method(:modulo))
      register_filter("newline_to_br", Liquid2::Filters.method(:newline_to_br))
      register_filter("plus", Liquid2::Filters.method(:plus))
      register_filter("prepend", Liquid2::Filters.method(:prepend))
      register_filter("reject", Liquid2::Filters.method(:reject))
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
      register_filter("sort_natural", Liquid2::Filters.method(:sort_natural))
      register_filter("sort_numeric", Liquid2::Filters.method(:sort_numeric))
      register_filter("sort", Liquid2::Filters.method(:sort))
      register_filter("split", Liquid2::Filters.method(:split))
      register_filter("strip_html", Liquid2::Filters.method(:strip_html))
      register_filter("strip_newlines", Liquid2::Filters.method(:strip_newlines))
      register_filter("strip", Liquid2::Filters.method(:strip))
      register_filter("sum", Liquid2::Filters.method(:sum))
      register_filter("times", Liquid2::Filters.method(:times))
      register_filter("truncate", Liquid2::Filters.method(:truncate))
      register_filter("truncatewords", Liquid2::Filters.method(:truncatewords))
      register_filter("uniq", Liquid2::Filters.method(:uniq))
      register_filter("url_encode", Liquid2::Filters.method(:url_encode))
      register_filter("url_decode", Liquid2::Filters.method(:url_decode))
      register_filter("upcase", Liquid2::Filters.method(:upcase))
      register_filter("where", Liquid2::Filters.method(:where))
    end

    def undefined(name, node: nil)
      @undefined.new(name, node: node)
    end

    # Trim _text_.
    def trim(text, left_trim, right_trim)
      case left_trim
      when "-"
        text.lstrip!
      when "~"
        text.sub!(/\A[\r\n]+/, "")
      end

      case right_trim
      when "-"
        text.rstrip!
      when "~"
        text.sub!(/[\r\n]+\Z/, "")
      end
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
      e.template_name = name unless e.template_name || e.is_a?(LiquidTemplateNotFoundError)
      raise e
    end

    # Merge environment globals with another namespace.
    def make_globals(namespace)
      return @globals if namespace.nil?
      return namespace if @globals.nil?

      (@globals || raise).merge(namespace)
    end
  end
end
