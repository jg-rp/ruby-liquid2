# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return _left_, or _default_ if _obj_ is `nil`, `false` or empty.
    # If _allow_false_ is `true`, _left_ is returned if _left_ is `false`.
    def self.default(left, default = "", context:, allow_false: false)
      return default if left.respond_to?(:force_default) && left.force_default

      obj = left.respond_to?(:to_liquid) ? left.to_liquid(context) : left
      falsey = allow_false ? left.nil? : !obj
      falsey || (left.respond_to?(:empty?) && left.empty?) ? default : left
    end
  end
end
