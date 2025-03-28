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
    # @param local_namespace_carry [Integer?]
    def initialize(
      template,
      globals: nil,
      disabled_tags: nil,
      copy_depth: 0,
      parent: nil,
      loop_carry: 1,
      local_namespace_carry: 0
    )
      @env = template.env
      @template = template
      @globals = globals || {}
      @disabled_tags = disabled_tags || []
      @copy_depth = copy_depth
      @parent = parent
      @loop_carry = loop_carry

      # The current size of the local namespace. _size_ is a non-specific measure of the
      # amount of memory used to store template local variables.
      @assign_score = local_namespace_carry

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
      @loops = [] # : Array[ForLoop]

      # A stack of interrupts used to signal breaking and continuing `for` loops.
      @interrupts = [] # : Array[Symbol]
    end

    # Add _key_ to the local scope with value _value_.
    # @param key [String]
    # @param value [Object]
    # @return [nil]
    def assign(key, value)
      @locals[key] = val
      if (limit = @env.local_namespace_limit)
        # Note that this approach does not account for overwriting keys/values
        # in the local scope. The assign score is always incremented.
        @assign_score += assign_score(value)
        raise "local namespace limit reached" if @assign_score > limit
      end
    end

    alias []= assign

    # Resolve _path_ to variable/data in the current scope.
    # @param path [Array<String|Integer>] Path segments.
    # @param token [Token?] An associated token to use for error context.
    # @param default [Object?] A default value to return if the path can no be resolved.
    # @return [Object]
    def fetch(path, token:, default: :undefined)
      root = path.first
      obj = @scope.fetch(root)

      if obj == :undefined
        if default == :undefined
          return @env.undefined(root,
                                hint: "#{root} is undefined",
                                token: token)
        end

        return default
      end

      path.to_enum.drop(1).each do |segment|
        obj = get_item(obj, segment)

        next unless obj == :undefined

        return default unless default == :undefined

        return @env.undefined(root,
                              hint: "#{segment} is undefined",
                              token: token)
      end

      obj
    end

    # Resolve variable _name_ in the current scope.
    # @param name [String]
    # @param default [Object?]
    # @return [Object?]
    def resolve(name, default: :undefined)
      obj = @scope.fetch(name)

      return obj unless obj == :undefined

      return default unless default == :undefined

      nil
    end

    alias [] resolve

    # Extend the scope of this context with the given namespace. Expects a block.
    # @param namespace [Hash<String, Object>]
    # @param template [Template?] Replace the current template for the duration of the block.
    def extend(namespace, template: nil)
      raise "context depth limit reached" if @scope.size > @env.context_depth_limit

      template_ = @template
      @template = template if template
      @scope << namespace
      yield
    ensure
      @template = template_
      @scope.pop
    end

    # Copy this render context and add _namespace_ to the new scope.
    # @param namespace [Hash<String, Object>]
    # @param template [Template?] The template object bound to the new context.
    # @param disabled_tags [Set<String>] Names of tags to disallow in the new context.
    # @param carry_loop_iterations [bool] If true, pass the current loop iteration count to the
    #   new context.
    # @param block_scope [bool] It true, retain the current scope in the new context. Otherwise
    #   only global variables will be included in the new context's scope.
    def copy(namespace,
             template: nil,
             disabled_tags: nil,
             carry_loop_iterations: false,
             block_scope: false)
      raise "context depth limit reached" if @copy_depth > @env.context_depth_limit

      loop_carry = if carry_loop_iterations
                     @loops.map(&:length).reduce(@loop_carry) { |acc, value| acc * value }
                   else
                     1
                   end

      scope = if block_scope
                ReadOnlyChainHash.new(@scope, namespace)
              else
                ReadOnlyChainHash.new(@globals, namespace)
              end

      new(template || @template,
          globals: scope,
          disabled_tags: disabled_tags,
          copy_depth: @copy_depth + 1,
          parent: self,
          loop_carry: loop_carry,
          local_namespace_carry: @assign_score)
    end

    def loop(namespace, forloop)
      # TODO
    end

    def parent_loop(token)
      # TODO:
    end

    def stop_index
      # TODO:
    end

    def raise_for_loop_limit(length: 1)
      # TODO:
    end

    def get_output_buffer(parent)
      # TODO:
    end

    def markup(s)
      # TODO:
    end

    def cycle
      # TODO:
    end

    def increment
      # TODO:
    end

    def decrement
      # TODO:
    end

    protected

    def assign_score(value)
      case value
      in String
        value.bytesize
      in Array
        value.sum(1) { |item| assign_score(item) } + 1
      in Hash
        value.sum(1) { |k, v| assign_score(k) + assign_score(v) }
      else
        1
      end
    end

    # Lookup _key_ in _obj_.
    # @param obj [Object]
    # @param key [untyped]
    # @return [untyped]
    def get_item(obj, key)
      if key.respond_to?(:to_liquid)
        method = key.method(:to_liquid)
        key = method.arity.zero? ? method.call : method.call(self)
      end

      return :undefined unless obj.respond_to?(:fetch)

      value = obj.fetch(key, :undefined)

      return value unless value == :undefined

      case key
      when "size"
        obj.respond_to?(:size) ? obj.size : :undefined
      when "first"
        obj.respond_to?(:first) ? obj.first : :undefined
      when "last"
        obj.respond_to?(:last) ? obj.last : :undefined
      end
    end
  end
end
