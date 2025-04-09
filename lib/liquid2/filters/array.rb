# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return the concatenation of items in _left_ separated by _sep_.
    # Coerce items in _left_ to strings if they aren't strings already.
    def self.join(left, sep = " ", context:)
      sep = Liquid2::Markup.soft_to_s(sep)
      if context.env.auto_escape
        Liquid2::Markup.join(Filters.to_enumerable(left), sep)
      else
        to_enumerable(left).map { |item| Liquid2.to_s(item) }.join(Liquid2.to_s(sep))
      end
    end

    # Return the first item in _left_.
    def self.first(left)
      case left
      when String
        left.each_char.first
      else
        left.first if left.respond_to?(:first)
      end
    end

    # The _compact_ filter.
    class Compact
      def validate(_env, node)
        if node.args.length > 1
          raise LiquidArgumentError.new(
            "#{node.name.inspect} expects at most one argument, got #{node.args.length}", node
          )
        end

        return unless node.args.length == 1

        arg = node.args.first.value

        return unless arg.is_a?(Liquid2::Lambda) && !arg.expr.is_a?(Liquid2::Path)

        raise LiquidArgumentError.new("#{node.name.inspect} expects a path to a variable", node)
      end

      # Return a copy of _left_ with nil items removed.
      # Coerce _left_ to an array-like object if it is not one already.
      #
      # If _key_ is given, assume items in _left_ are hash-like and remove items from _left_
      # where `item.fetch(key, nil)` is nil.
      #
      # If key is not `:undefined`, coerce it to a string before calling `fetch` on items in
      # _left_.
      def call(left, key = :undefined, context:)
        left = Liquid2::Filters.to_enumerable(left)

        case key
        when Liquid2::Lambda
          key.map(context, left).zip(left).reject do |r, _i|
            r.nil? || r.is_a?(Liquid2::Undefined)
          end.map(&:last)
        when :undefined
          left.compact
        else
          # TODO: stringify key?
          left.reject do |item|
            item.respond_to?(:fetch) ? item.fetch(key, nil).nil? : true
          end
        end
      end

      def parameters
        method(:call).parameters
      end
    end

    # Return _left_ concatenated with _right_, or nil if _right_ is not an array.
    # Coerce _left_ to an arrays if it isn't an array already.
    def self.concat(left, right)
      unless right.respond_to?(:to_ary)
        raise Liquid2::LiquidArgumentError.new("expected an array", nil)
      end

      Filters.to_enumerable(left).to_a.concat(right)
    end
  end
end
