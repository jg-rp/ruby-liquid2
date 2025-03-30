# frozen_string_literal: true

require_relative "parser"
require_relative "template"
require_relative "filters/slice"
require_relative "nodes/tags/assign"

module Liquid2
  class Environment
    attr_reader :mode, :tags, :local_namespace_limit, :context_depth_limit, :loop_iteration_limit,
                :output_stream_limit, :filters, :auto_escape

    def initialize
      # A mapping of tag names to objects responding to
      # `parse: (TokenStream, Parser) -> Tag`
      @tags = { "assign" => AssignTag }

      # A mapping of filter names to objects responding to `#call(left, ...)`,
      # along with a flag to indicate if the callable accepts a `context`
      # keyword argument.
      @filters = {}

      @parser = Parser.new(self)
      @mode = :lax
      @auto_escape = false

      @local_namespace_limit = nil
      @context_depth_limit = 30
      @loop_iteration_limit = nil
      @output_stream_limit = nil

      @suppress_blank_control_flow_blocks = false

      setup_tags_and_filters
    end

    # @param source [String] template source text.
    # @return [Template]
    def parse(source)
      Template.new(self, @parser.parse(source))
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
      with_context = callable.parameters.index { |(kind, param)| kind == :key && param == :context }
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
      register_filter("downcase", ->(left) { Liquid.to_s(left).downcase })
      register_filter("slice", SliceFilter.new)
      register_filter("split", ->(left, sep) { Liquid2.to_s(left).split(Liquid2.to_s(sep)) })
      register_filter("join", ->(left, sep) { left.join(Liquid2.to_s(sep)) })
    end
  end
end
