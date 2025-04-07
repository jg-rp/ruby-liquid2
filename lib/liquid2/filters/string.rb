# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return _left_ concatenated with _right_.
    # Coerce _left_ and _right_ to strings if they aren't strings already.
    def self.append(left, right)
      Liquid2.to_s(left) + Liquid2.to_s(right)
    end
  end
end
