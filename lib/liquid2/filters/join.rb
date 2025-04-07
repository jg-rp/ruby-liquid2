# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return the concatenation of items in _left_ separated by _sep_.
    def self.join(left, sep = " ", context:)
      sep = Liquid2::Markup.soft_to_s(sep)
      if context.env.auto_escape
        Liquid2::Markup.join(Filters.to_enumerable(left), sep)
      else
        to_enumerable(left).map { |item| Liquid2.to_s(item) }.join(Liquid2.to_s(sep))
      end
    end
  end
end
