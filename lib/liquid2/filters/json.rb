# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return _left_ serialized in JSON format.
    def self.json(left, pretty: false)
      if pretty
        JSON.pretty_generate(left)
      else
        JSON.generate(left)
      end
    end
  end
end
