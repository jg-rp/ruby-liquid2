# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # The _find_ filter.
    class Find
      def validate(_env, node)
        unless [1, 2].include?(node.args.length)
          raise LiquidArgumentError.new(
            "#{node.name.inspect} expects one or two arguments, got #{node.args.length}", node
          )
        end

        arg = node.args.first.value

        return unless arg.is_a?(Lambda) && node.args.length != 1

        raise LiquidArgumentError.new(
          "#{node.name.inspect} expects one argument when given a lambda expression", node
        )
      end

      def call(left, key, value = nil, context:)
        left = Liquid2::Filters.to_enumerable(left)

        if key.is_a?(Liquid2::Lambda)
          key.map(context, left).zip(left).reject do |r, i|
            return i unless r.is_a?(Liquid2::Undefined) || !Liquid2.truthy?(context, r)
          end
        elsif !value.nil? && !Liquid2.undefined?(value)
          left.each do |item|
            return item if fetch(item, key) == value
          end
        else
          left.each do |item|
            return item if fetch(item, key)
          end
        end

        nil
      end

      def parameters
        method(:call).parameters
      end

      protected

      def fetch(obj, key, default = nil)
        case obj
        when String
          key.is_a?(String) && obj.include?(key) ? key : default
        when Integer
          key.is_a?(Integer) ? obj == key : default
        else
          item = obj.fetch(key, nil) if obj.respond_to?(:fetch)
          item.nil? ? default : item
        end
      rescue ::ArgumentError
        default
      end
    end

    # The _find_index_ filter
    class FindIndex < Find
      def call(left, key, value = nil, context:)
        left = Liquid2::Filters.to_enumerable(left)

        if key.is_a?(Liquid2::Lambda)
          key.map(context, left).reject.with_index do |r, index|
            return index unless r.is_a?(Liquid2::Undefined) || !Liquid2.truthy?(context, r)
          end
        elsif !value.nil? && !Liquid2.undefined?(value)
          left.each_with_index do |item, index|
            return index if fetch(item, key) == value
          end
        else
          left.each_with_index do |item, index|
            return index if fetch(item, key)
          end
        end

        nil
      end
    end

    # The _has_ filter.
    class Has < Find
      def call(left, key, value = nil, context:)
        left = Liquid2::Filters.to_enumerable(left)

        if key.is_a?(Liquid2::Lambda)
          key.map(context, left).reject do |r|
            return true unless r.is_a?(Liquid2::Undefined) || !Liquid2.truthy?(context, r)
          end
        elsif !value.nil? && !Liquid2.undefined?(value)
          left.each do |item|
            return true if fetch(item, key) == value
          end
        else
          left.each do |item|
            return true if fetch(item, key)
          end
        end

        false
      end
    end
  end
end
