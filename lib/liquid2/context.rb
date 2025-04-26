# frozen_string_literal: true

require_relative "utils/chain_hash"

module Liquid2
  # Hash-like obj for resolving built-in dynamic objs.
  class BuiltIn
    def key?(key)
      %w[now today].include?(key)
    end

    def fetch(key, default = :undefined)
      case key
      when "now", "today"
        Time.now
      else
        default
      end
    end

    def [](key)
      case key
      when "now", "today"
        Time.now
      end
    end
  end

  # Per render contextual information. A new RenderContext is created automatically
  # every time `Template#render` is called.
  class RenderContext
    attr_reader :env, :template, :disabled_tags, :globals
    attr_accessor :interrupts

    BUILT_IN = BuiltIn.new

    # @param template [Template]
    # @param globals [Hash<String, Object>?]
    # @param disabled_tags [Array<String>?]
    # @param copy_depth [Integer?]
    # @param parent [RenderContext?]
    # @param parent_scope [Array[_Namespace]] Namespaces from a parent render context.
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
      @globals = globals || {} # steep:ignore UnannotatedEmptyCollection
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
      @counters = Hash.new(0)

      # Namespaces are searched from right to left. When a RenderContext is extended, the
      # temporary namespace is pushed to the end of this queue.
      # TODO: exclude @globals if globals is empty
      @scope = ReadOnlyChainHash.new(@counters, BUILT_IN, @globals, @locals)

      # A namespace supporting stateful tags, such as `cycle` and `increment`.
      # It's OK to use this hash for storing custom tag state.
      @tag_namespace = {
        cycles: Hash.new(0),
        stop_index: {},
        extends: Hash.new { |hash, key| hash[key] = [] },
        macros: {}
      }

      # A stack of forloop objs used for populating forloop.parentloop.
      @loops = [] # : Array[ForLoop]

      # A stack of interrupts used to signal breaking and continuing `for` loops.
      @interrupts = [] # : Array[Symbol]
    end

    # Evaluate _obj_ as an expression in the render current context.
    def evaluate(obj)
      obj.respond_to?(:evaluate) ? obj.evaluate(self) : obj
    end

    # Add _key_ to the local scope with value _value_.
    # @param key [String]
    # @param value [Object]
    # @return [nil]
    def assign(key, value)
      @locals[key] = value
      if (limit = @env.local_namespace_limit)
        # Note that this approach does not account for overwriting keys/values
        # in the local scope. The assign score is always incremented.
        @assign_score += assign_score(value)
        raise LiquidResourceLimitError, "local namespace limit reached" if @assign_score > limit
      end
    end

    alias []= assign

    # Resolve _path_ to variable/data in the current scope.
    # @param head [String|Integer] First segment of the path.
    # @param path [Array<String|Integer>] Remaining path segments.
    # @param node [Node?] An associated token to use for error context.
    # @param default [Object?] A default value to return if the path can no be resolved.
    # @return [Object]
    def fetch(head, path, node:, default: :undefined)
      obj = @scope.fetch(evaluate(head))

      if obj == :undefined
        return @env.undefined(head, node: node) if default == :undefined

        return default
      end

      index = 0
      while (segment = path[index])
        index += 1
        segment = evaluate(segment)
        segment = segment.to_liquid(self) if segment.respond_to?(:to_liquid)

        if obj.respond_to?(:[]) &&
           ((obj.respond_to?(:key?) && obj.key?(segment)) ||
            (obj.respond_to?(:fetch) && segment.is_a?(Integer)))
          obj = obj[segment]
          next
        end

        obj = if segment == "size" && obj.respond_to?(:size)
                obj.size
              elsif segment == "first" && obj.respond_to?(:first)
                obj.first
              elsif segment == "last" && obj.respond_to?(:last)
                obj.last
              else
                return default == :undefined ? @env.undefined(head, node: node) : default
              end
      end

      obj
    end

    # Resolve variable _name_ in the current scope.
    # @param name [String]
    # @return [Object?]
    def resolve(name) = @scope.fetch(name)

    alias [] resolve

    # Extend the scope of this context with the given namespace. Expects a block.
    # @param namespace [Hash<String, Object>]
    # @param template [Template?] Replace the current template for the duration of the block.
    def extend(namespace, template: nil)
      if @scope.size > @env.context_depth_limit
        raise LiquidResourceLimitError, "context depth limit reached"
      end

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
    # @param template [Template?] The template obj bound to the new context.
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
      if @copy_depth > @env.context_depth_limit
        raise LiquidResourceLimitError, "context depth limit reached"
      end

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

      self.class.new(template || @template,
                     globals: scope,
                     disabled_tags: disabled_tags,
                     copy_depth: @copy_depth + 1,
                     parent: self,
                     loop_carry: loop_carry,
                     local_namespace_carry: @assign_score)
    end

    # Push a new namespace and forloop for the duration of a block.
    # @param namespace [Hash<String, Object>]
    # @param forloop [ForLoop]
    def loop(namespace, forloop)
      raise_for_loop_limit(length: forloop.length)
      @loops << forloop
      @scope << namespace
      yield
    ensure
      @scope.pop
      @loops.pop
    end

    # Return the last ForLoop obj if one is available, or an instance of Undefined otherwise.
    def parent_loop(node)
      return @env.undefined("parentloop", node: node) if @loops.empty?

      @loops.last
    end

    # Get or set the stop index of a for loop.
    def stop_index(key, index: nil)
      if index
        @tag_namespace[:stop_index][key] = index
      else
        @tag_namespace[:stop_index].fetch(key, 0)
      end
    end

    def raise_for_loop_limit(length: 1)
      return nil unless @env.loop_iteration_limit

      loop_count = @loops.map(&:length).reduce(length * @loop_carry) { |acc, value| acc * value }

      return unless loop_count > (@env.loop_iteration_limit || raise)

      raise LiquidResourceLimitError, "loop iteration limit reached"
    end

    def get_output_buffer(parent_buffer)
      return StringIO.new unless @env.output_stream_limit

      carry = parent_buffer.is_a?(LimitedStringIO) ? parent_buffer.size : 0
      LimitedStringIO.new((@env.output_stream_limit || raise) - carry)
    end

    def cycle(key, length)
      namespace = @tag_namespace[:cycles]
      index = namespace[key]
      namespace[key] += 1
      index % length
    end

    def increment(name)
      val = @counters[name]
      @counters[name] = val + 1
      val
    end

    def decrement(name)
      val = @counters[name] - 1
      @counters[name] = val
      val
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
  end
end
