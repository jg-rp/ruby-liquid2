# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # The _reject_ filter.
    class Reject
      def call(left, key, value = nil, context:)
        left = Liquid2::Filters.to_enumerable(left)

        if key.is_a?(Liquid2::Lambda)
          key.map(context, left).zip(left).reject do |r, _item|
            r.is_a?(Liquid2::Undefined) || Liquid2.truthy?(context, r)
          end.map(&:last)
        elsif !value.nil? && !Liquid2.undefined?(value)
          key = Liquid2.to_s(key)
          left.reject do |item|
            fetch(item, key) == value
          end
        else
          key = Liquid2.to_s(key)
          left.reject do |item|
            Liquid2.truthy?(context, fetch(item, key))
          end
        end
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
  end
end
