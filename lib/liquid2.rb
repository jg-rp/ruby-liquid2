# frozen_string_literal: true

require_relative "liquid2/environment"
require_relative "liquid2/lexer"
require_relative "liquid2/parser"
require_relative "liquid2/version"
require_relative "liquid2/utils/chain_hash"

module Liquid2
  def self.to_liquid_string(obj, auto_escape: false)
    # TODO:
    obj.to_s
  end

  def self.to_liquid_int(obj, default: 0)
    # TODO:
    obj.to_i
  end
end
