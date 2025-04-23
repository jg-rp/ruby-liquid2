# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return the concatenation of items in _left_ separated by _sep_.
    # Coerce items in _left_ to strings if they aren't strings already.
    def self.join(left, sep = " ")
      sep = Liquid2.to_s(sep)
      to_enumerable(left).map { |item| Liquid2.to_s(item) }.join(Liquid2.to_s(sep))
    end

    # Return a copy of _left_ with nil items removed.
    # Coerce _left_ to an array-like object if it is not one already.
    #
    # If _key_ is given, assume items in _left_ are hash-like and remove items from _left_
    # where `item.fetch(key, nil)` is nil.
    #
    # If key is not `:undefined`, coerce it to a string before calling `fetch` on items in
    # _left_.
    def self.compact(left, key = :undefined, context:)
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

    # Return _left_ concatenated with _right_, or nil if _right_ is not an array.
    # Coerce _left_ to an array if it isn't an array already.
    def self.concat(left, right)
      unless right.respond_to?(:to_ary)
        raise Liquid2::LiquidArgumentError.new("expected an array", nil)
      end

      Filters.to_enumerable(left).to_a.concat(right)
    end

    def self.find(left, key, value = nil, context:)
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

    def self.find_index(left, key, value = nil, context:)
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

    def self.has(left, key, value = nil, context:)
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

    # Return the first item in _left_, or `nil` if _left_ does not have a first item.
    def self.first(left)
      case left
      when String
        left[0]
      else
        left.first if left.respond_to?(:first)
      end
    end

    # Return the last item in _left_, or `nil` if _left_ does not have a last item.
    def self.last(left)
      case left
      when String
        left[-1]
      else
        left.last if left.respond_to?(:last)
      end
    end

    def self.map(left, key, context:)
      left = Liquid2::Filters.to_enumerable(left)

      if key.is_a?(Liquid2::Lambda)
        key.map(context, left).map do |item|
          item.is_a?(Liquid2::Undefined) ? nil : item
        end
      else
        key = Liquid2.to_s(key)
        left.map { |item| item[key] }
      end
    end

    # Return _left_ with all items in reverse order.
    # Coerce _left_ to an array if it isn't an array already.
    def self.reverse(left)
      to_enumerable(left).to_a.reverse
    end

    def self.reject(left, key, value = nil, context:)
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

    def self.where(left, key, value = nil, context:)
      left = Liquid2::Filters.to_enumerable(left)

      if key.is_a?(Liquid2::Lambda)
        key.map(context, left).zip(left).filter do |r, _item|
          r.is_a?(Liquid2::Undefined) || Liquid2.truthy?(context, r)
        end.map(&:last)
      elsif !value.nil? && !Liquid2.undefined?(value)
        key = Liquid2.to_s(key)
        left.filter do |item|
          fetch(item, key) == value
        end
      else
        key = Liquid2.to_s(key)
        left.filter do |item|
          Liquid2.truthy?(context, fetch(item, key))
        end
      end
    end
  end
end
