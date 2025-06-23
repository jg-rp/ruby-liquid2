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
require_relative "nodes/tags/extends"
require_relative "nodes/tags/for"
require_relative "nodes/tags/if"
require_relative "nodes/tags/include"
require_relative "nodes/tags/increment"
require_relative "nodes/tags/inline_comment"
require_relative "nodes/tags/liquid"
require_relative "nodes/tags/macro"
require_relative "nodes/tags/raw"
require_relative "nodes/tags/render"
require_relative "nodes/tags/tablerow"
require_relative "nodes/tags/unless"
require_relative "nodes/tags/with"

module Liquid2
  # Template parsing and rendering configuration.
  #
  # A Liquid2::Environment is where you might register custom tags and filters,
  # or store global context data that should be available to all templates.
  #
  # `Liquid2.parse(source)` is equivalent to `Liquid2::Environment.new.parse(source)`.
  class Environment
    attr_reader :tags, :local_namespace_limit, :context_depth_limit, :loop_iteration_limit,
                :output_stream_limit, :filters, :suppress_blank_control_flow_blocks,
                :shorthand_indexes, :falsy_undefined, :arithmetic_operators, :markup_comment_prefix,
                :markup_comment_suffix, :markup_out_end, :markup_out_start, :markup_tag_end,
                :markup_tag_start, :re_tag_name, :re_word, :re_int, :re_float,
                :re_double_quote_string_special, :re_single_quote_string_special, :re_markup_start,
                :re_markup_end, :re_markup_end_chars, :re_up_to_markup_start, :re_punctuation,
                :re_up_to_inline_comment_end, :re_up_to_raw_end, :re_block_comment_chunk,
                :re_up_to_doc_end, :re_line_statement_comment

    # @param context_depth_limit [Integer] The maximum number of times a render context can
    #   be extended or copied before a `Liquid2::LiquidResourceLimitError`` is raised.
    # @param globals [Hash[String, untyped]?] Variables that are available to all templates
    #   rendered from this environment.
    # @param loader [Liquid2::Loader] An instance of `Liquid2::Loader`. A template loader
    #   is responsible for finding and reading templates for `{% include %}` and
    #   `{% render %}` tags, or when calling `Liquid2::Environment.get_template(name)`.
    # @param local_namespace_limit [Integer?] The maximum allowed "size" of the template
    #   local namespace (variables from `assign` and `capture` tags) before a
    #   `Liquid2::LiquidResourceLimitError`` is raised.
    # @param loop_iteration_limit [Integer?] The maximum number of loop iterations allowed
    #   before a `LiquidResourceLimitError` is raised.
    # @param markup_comment_prefix [String] The string of characters that indicate the start of a
    #   Liquid comment. This should include a single trailing `#`. Additional, variable length
    #   hashes will be handled by the tokenizer. It is not possible to change comment syntax to not
    #   use `#`.
    # @param markup_comment_suffix [String] The string of characters that indicate the end of a
    #   Liquid comment, excluding any hashes.
    # @param markup_out_end [String] The string of characters that indicate the end of a Liquid
    #   output statement.
    # @param markup_out_start [String] The string of characters that indicate the start of a Liquid
    #   output statement.
    # @param markup_tag_end [String] The string of characters that indicate the end of a Liquid tag.
    # @param markup_tag_start [String] The string of characters that indicate the start of a Liquid
    #   tag.
    # @param output_stream_limit [Integer?] The maximum number of bytes that can be written
    #   to a template's output buffer before a `LiquidResourceLimitError` is raised.
    # @param parser [singleton(Parser)] `Liquid2::Parser` or a subclass of it.
    # @param scanner [singleton(Scanner)] `Liquid2::Scanner` or a subclass of it.
    # @param shorthand_indexes [bool] When `true`, allow shorthand dotted array indexes as
    #   well as bracketed indexes in variable paths. Defaults to `false`.
    # @param suppress_blank_control_flow_blocks [bool] When `true`, suppress blank control
    #   flow block output, so as not to include unnecessary whitespace. Defaults to `true`.
    # @param undefined [singleton(Liquid2::Undefined)] A singleton returning an instance of
    #   `Liquid2::Undefined`, which is used to represent template variables that don't exist.
    def initialize(
      arithmetic_operators: false,
      context_depth_limit: 30,
      falsy_undefined: true,
      globals: nil,
      loader: nil,
      local_namespace_limit: nil,
      loop_iteration_limit: nil,
      markup_comment_prefix: "{#",
      markup_comment_suffix: "}",
      markup_out_end: "}}",
      markup_out_start: "{{",
      markup_tag_end: "%}",
      markup_tag_start: "{%",
      output_stream_limit: nil,
      parser: Parser,
      scanner: Scanner,
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

      # When `true`, arithmetic operators `+`, `-`, `*`, `/`, `%` and `**` are enabled.
      # Defaults to `false`.
      @arithmetic_operators = arithmetic_operators

      # The maximum number of times a render context can be extended or copied before
      # a Liquid2::LiquidResourceLimitError is raised.
      @context_depth_limit = context_depth_limit

      # Variables that are available to all templates rendered from this environment.
      @globals = globals

      # An instance of `Liquid2::Loader`. A template loader is responsible for finding and
      # reading templates for `{% include %}` and `{% render %}` tags, or when calling
      # `Liquid2::Environment.get_template(name)`.
      @loader = loader || HashLoader.new({})

      # The maximum allowed "size" of the template local namespace (variables from `assign`
      # and `capture` tags) before a Liquid2::LiquidResourceLimitError is raised.
      @local_namespace_limit = local_namespace_limit

      # The maximum number of loop iterations allowed before a `LiquidResourceLimitError`
      # is raised.
      @loop_iteration_limit = loop_iteration_limit

      # The maximum number of bytes that can be written to a template's output buffer
      # before a `LiquidResourceLimitError` is raised.
      @output_stream_limit = output_stream_limit

      # Liquid2::Scanner or a subclass of it. This is used to tokenize Liquid source
      # text before parsing it.
      @scanner = scanner

      # Liquid2::Parser or a subclass of it. The parser takes tokens from the scanner
      # and produces an abstract syntax tree.
      @parser = parser

      # We reuse the same string scanner when parsing templates for improved performance.
      # TODO: Is this going to cause issues in multi threaded environments?
      @string_scanner = StringScanner.new("")

      # When `true`, allow shorthand dotted array indexes as well as bracketed indexes
      # in variable paths. Defaults to `false`.
      @shorthand_indexes = shorthand_indexes

      # When `true`, suppress blank control flow block output, so as not to include
      # unnecessary whitespace. Defaults to `true`.
      @suppress_blank_control_flow_blocks = suppress_blank_control_flow_blocks

      # A singleton returning an instance of `Liquid2::Undefined`, which is used to
      # represent template variables that don't exist.
      @undefined = undefined

      # When `true` (the default), undefined variables are considered falsy and do not
      # raise an error when tested for truthiness.
      @falsy_undefined = falsy_undefined

      # The string of characters that indicate the start of a Liquid output statement.
      @markup_out_start = markup_out_start

      # The string of characters that indicate the end of a Liquid output statement.
      @markup_out_end = markup_out_end

      # The string of characters that indicate the start of a Liquid tag.
      @markup_tag_start = markup_tag_start

      # The string of characters that indicate the end of a Liquid tag.
      @markup_tag_end = markup_tag_end

      # The string of characters that indicate the start of a Liquid comment. This should
      # include a single trailing `#`. Additional, variable length hashes will be handled
      # by the tokenizer. It is not possible to change comment syntax to not use `#`.
      @markup_comment_prefix = markup_comment_prefix

      # The string of characters that indicate the end of a Liquid comment, excluding any
      # hashes.
      @markup_comment_suffix = markup_comment_suffix

      # You might need to override `setup_scanner` if you've specified custom markup
      # delimiters and they conflict with standard punctuation.
      setup_scanner

      # Override `setup_tags_and_filters` in environment subclasses to configure custom
      # tags and/or filters.
      setup_tags_and_filters
    end

    # Parse _source_ text as a template.
    # @param source [String] template source text.
    # @return [Template]
    def parse(source, name: "", path: nil, up_to_date: nil, globals: nil, overlay: nil)
      Template.new(
        self,
        source,
        @parser.new(self, @scanner.tokenize(self, source, @string_scanner), source.length).parse,
        name: name, path: path, up_to_date: up_to_date,
        globals: make_globals(globals), overlay: overlay
      )
    rescue LiquidError => e
      e.source = source unless e.source
      e.template_name = name unless e.template_name || name.empty?
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

    # Add or replace a tag.
    # @param name [String] The tag's name, as used by template authors.
    # @param tag [responds to parse: ([Symbol, String?, Integer], Parser) -> Tag]
    def register_tag(name, tag)
      @tags[name] = tag
    end

    # Remove a tag from the tag register.
    # @param name [String] The name of the tag.
    # @return [_Tag | nil]
    def delete_tag(name)
      @tags.delete(name)
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
      @tags["extends"] = ExtendsTag
      @tags["block"] = BlockTag
      @tags["for"] = ForTag
      @tags["if"] = IfTag
      @tags["include"] = IncludeTag
      @tags["increment"] = IncrementTag
      @tags["liquid"] = LiquidTag
      @tags["macro"] = MacroTag
      @tags["call"] = CallTag
      @tags["raw"] = RawTag
      @tags["render"] = RenderTag
      @tags["tablerow"] = TableRowTag
      @tags["unless"] = UnlessTag
      @tags["with"] = WithTag

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
      register_filter("range", Liquid2::Filters.method(:better_slice))
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

    # Compile regular expressions for use by the tokenizer attached to this environment.
    def setup_scanner
      # A regex pattern matching Liquid tag names. Should include `#` for inline comments.
      @re_tag_name = /(?:[a-z][a-z_0-9]*|#)/

      # A regex pattern matching keywords and/or variable/path names. Replace this if
      # you want to disable Unicode characters in identifiers, for example.
      @re_word = /[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*/

      # Patterns matching literal integers and floats, possibly in scientific notation.
      # You could simplify these to disable scientific notation.
      @re_int = /-?\d+(?:[eE]\+?\d+)?/
      @re_float = /((?:-?\d+\.\d+(?:[eE][+-]?\d+)?)|(-?\d+[eE]-\d+))/

      # Patterns matching escape sequences, interpolation and end of string in string literals.
      # You could remove `\$` from these to disable string interpolation.
      @re_double_quote_string_special = /[\\"\$]/
      @re_single_quote_string_special = /[\\'\$]/

      # rubocop: disable Layout/LineLength

      # A regex pattern matching the start of some Liquid markup. Could be the start of an
      # output statement, tag or comment. Traditionally `{{`, `{%` and `{#`, respectively.
      @re_markup_start = /#{Regexp.escape(@markup_out_start)}|#{Regexp.escape(@markup_tag_start)}|#{Regexp.escape(@markup_comment_prefix)}/

      # A regex pattern matching the end of some Liquid markup. Could be the end of
      # an output statement or tag. Traditionally `}}`, `%}`, respectively.
      @re_markup_end = /#{Regexp.escape(@markup_out_end)}|#{Regexp.escape(@markup_tag_end)}/

      # A regex pattern matching any one of the possible characters ending some Liquid
      # markup. This is used to detect incomplete and malformed markup and provide
      # helpful error messages.
      @re_markup_end_chars = /[#{Regexp.escape((@markup_out_end + @markup_tag_end).each_char.uniq.join)}]/

      @re_up_to_markup_start = /(?=#{Regexp.escape(@markup_out_start)}|#{Regexp.escape(@markup_tag_start)}|#{Regexp.escape(@markup_comment_prefix)})/
      @re_punctuation = %r{(?!#{@re_markup_end})(\?|\[|\]|\|{1,2}|\.{1,2}|,|:|\(|\)|[<>=!]+|[+\-%*/]+(?!#{@re_markup_end_chars}))}
      @re_up_to_inline_comment_end = /(?=([+\-~])?#{Regexp.escape(@markup_tag_end)})/
      @re_up_to_raw_end = /(?=(#{Regexp.escape(@markup_tag_start)}[+\-~]?\s*endraw\s*[+\-~]?#{Regexp.escape(@markup_tag_end)}))/
      @re_block_comment_chunk = /(#{Regexp.escape(@markup_tag_start)}[+\-~]?\s*(comment|raw|endcomment|endraw)\s*[+\-~]?#{Regexp.escape(@markup_tag_end)})/
      @re_up_to_doc_end = /(?=(#{Regexp.escape(@markup_tag_start)}[+\-~]?\s*enddoc\s*[+\-~]?#{Regexp.escape(@markup_tag_end)}))/
      @re_line_statement_comment = /(?=([\r\n]+|-?#{Regexp.escape(@markup_tag_end)}))/

      # rubocop: enable Layout/LineLength
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
