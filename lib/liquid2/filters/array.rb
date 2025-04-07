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

    # Return a copy of _left_ with nil items removed.
    # Coerce _left_ to an array-like object if it is not one already.
    #
    # If _key_ is given, assume items in _left_ are hash-like and remove items from _left_
    # where `item.fetch(key, nil)` is nil.
    #
    # If key is not `:undefined`, coerce it to a string before calling `fetch` on items in
    # _left_.
    def self.compact(left, key = :undefined)
      # TODO: filter argument validation
      return to_enumerable(left).compact if key == :undefined

      key = Liquid2.to_s(key)
      to_enumerable(left).reject do |item|
        item.respond_to?(:fetch) ? item.fetch(key, nil).nil? : true
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
  end
end
