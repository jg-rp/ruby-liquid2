# frozen_string_literal: true

require_relative "liquid2/environment"
require_relative "liquid2/context"
require_relative "liquid2/lexer"
require_relative "liquid2/loader"
require_relative "liquid2/parser"
require_relative "liquid2/version"
require_relative "liquid2/undefined"
require_relative "liquid2/utils/chain_hash"
require_relative "liquid2/utils/markup"
require_relative "liquid2/utils/unescape"

module Liquid2
  DEFAULT_ENVIRONMENT = Environment.new

  def self.to_liquid_string(obj, auto_escape: false)
    if obj.is_a?(Array)
      s = obj.map { |item| to_liquid_string(item, auto_escape: auto_escape) }.join
      auto_escape ? Markup.new(s) : s
    else
      auto_escape ? Markup.escape(obj) : obj.to_s
    end
  end

  def self.to_liquid_int(obj, default: 0)
    obj.to_f.to_i
  end

  # Return `true` if _obj_ is Liquid truthy.
  # @param context [RenderContext]
  # @param obj [Object]
  # @return [bool]
  def self.truthy?(context, obj)
    obj = obj.to_liquid(context) if obj.respond_to?(:to_liquid)
    !!obj
  end

  # Return `true` if _obj_ is undefined.
  def self.undefined?(obj)
    obj.is_a?(Undefined)
  end

  class << self
    alias to_s to_liquid_string
    alias to_i to_liquid_int
  end
end
