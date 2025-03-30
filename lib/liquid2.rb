# frozen_string_literal: true

require_relative "liquid2/environment"
require_relative "liquid2/context"
require_relative "liquid2/lexer"
require_relative "liquid2/parser"
require_relative "liquid2/version"
require_relative "liquid2/utils/chain_hash"
require_relative "liquid2/utils/markup"

module Liquid2
  DEFAULT_ENVIRONMENT = Environment.new

  def self.to_liquid_string(obj, auto_escape: false)
    # TODO:
    obj.to_s
  end

  def self.to_liquid_int(obj, default: 0)
    # TODO:
    obj.to_i
  end

  # Return `true` if _obj_ is Liquid truthy.
  # @param context [RenderContext]
  # @param obj [Object]
  # @return [bool]
  def self.truthy?(context, obj)
    obj = obj.to_liquid(context) if obj.respond_to?(:to_liquid)
    !!obj
  end

  class << self
    alias to_s to_liquid_string
    alias to_i to_liquid_int
  end
end
