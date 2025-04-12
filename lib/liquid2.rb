# frozen_string_literal: true

require "json"
require_relative "liquid2/environment"
require_relative "liquid2/context"
require_relative "liquid2/filter"
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

  # Stringify an object. Use this anywhere a string is expected, like in a filter.
  def self.to_liquid_string(obj)
    case obj
    when Hash, Array
      JSON.generate(obj)
    else
      Markup.soft_to_s(obj)
    end
  end

  # Stringify an object for output. Use this when writing directly to an output buffer.
  def self.to_output_string(obj, auto_escape: false)
    case obj
    when Array
      # Concatenate string representations of array elements.
      s = obj.map do |item|
        auto_escape ? Markup.escape(item) : Liquid2.to_s(item)
      end.join
      auto_escape ? Markup.new(s) : s
    when BigDecimal
      # TODO: test capture
      # TODO: are there any scenarios where we need to cast to_f before output?
      obj.to_f.to_s
    else
      auto_escape ? Markup.escape(obj) : Liquid2.to_s(obj)
    end
  end

  def self.to_liquid_int(obj, default: 0)
    Float(obj).to_i
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
    alias to_output_s to_output_string
    alias to_i to_liquid_int
  end
end
