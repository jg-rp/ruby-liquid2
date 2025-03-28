# frozen_string_literal: true

require_relative "utils/chain_hash"

module Liquid2
  # Hash-like object for resolving built-in dynamic objects.
  class BuiltIn
    def [](_key)
      raise "TODO"
    end
  end

  # Per render contextual information. A new RenderContext is created automatically
  # every time `Template#render` is called.
  class RenderContext
    attr_reader :env, :template

    BUILT_IN = BuiltIn.new

    # @param template [Template]
    # @param globals [Hash<String, Object>?]
    # @param disabled_tags [Array<String>?]
    # @param copy_depth [Integer?]
    # @param parent [RenderContext?]
    # @param loop_carry [Integer?]
    # @param namespace_carry [Integer?]
    def initialize(
      template,
      globals: nil,
      disabled_tags: nil,
      copy_depth: 0,
      parent: nil,
      loop_carry: 1,
      namespace_carry: 0
    )
      @env = template.env
      @template = template
      @globals = globals || {}
      @disabled_tags = disabled_tags || []
      @copy_depth = copy_depth
      @parent = parent
      @loop_carry = loop_carry
      @namespace_carry = namespace_carry

      # A namespace for template local variables (those bound with `assign` or `capture`).
      @locals = {}

      # A namespace for `increment` and `decrement` counters.
      @counters = {}

      # Namespaces are searched from right to left. When a RenderContext is extended, the
      # temporary namespace is pushed to the end of this queue.
      @scope = ReadOnlyChainHash.new([@counters, BUILT_IN, @globals, @locals])

      # A namespace supporting stateful tags, such as `cycle` and `increment`.
      # It's OK to use this hash for storing custom tag state.
      @tag_namespace = {
        cycles: {},
        stop_index: {},
        extends: Hash.new { |hash, key| hash[key] = [] },
        macros: {}
      }

      # A stack of forloop objects used for populating forloop.parentloop.
      @loops = []
    end
  end
end
