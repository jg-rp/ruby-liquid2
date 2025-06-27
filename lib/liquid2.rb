# frozen_string_literal: true

require "json"
require_relative "liquid2/environment"
require_relative "liquid2/context"
require_relative "liquid2/filter"
require_relative "liquid2/scanner"
require_relative "liquid2/loader"
require_relative "liquid2/parser"
require_relative "liquid2/version"
require_relative "liquid2/undefined"
require_relative "liquid2/utils/chain_hash"
require_relative "liquid2/utils/unescape"
require_relative "liquid2/static_analysis"
require_relative "liquid2/loaders/file_system_loader"

# Liquid template engine.
module Liquid2
  DEFAULT_ENVIRONMENT = Environment.new

  # Parse _source_ text as a template using the default Liquid environment.
  # @param source [String]
  # @param globals [?Hash[String, untyped]?]
  # @return [Template]
  def self.parse(source, globals: nil)
    DEFAULT_ENVIRONMENT.parse(source, globals: globals)
  end

  # Parse and render template _source_ with _data_ as template variables and
  # the default Liquid environment.
  # @param source [String]
  # @param data [?Hash[String, untyped]?]
  # @return [String]
  def self.render(source, data = nil)
    DEFAULT_ENVIRONMENT.render(source, data)
  end

  # Stringify an object. Use this anywhere a string is expected, like in a filter.
  def self.to_liquid_string(obj)
    case obj
    when Hash, Array
      JSON.generate(obj)
    else
      obj.to_s
    end
  end

  # Stringify an object for output. Use this when writing directly to an output buffer.
  def self.to_output_string(obj)
    case obj
    when Array
      # Concatenate string representations of array elements.
      obj.map do |item|
        Liquid2.to_s(item)
      end.join
    when BigDecimal
      # TODO: test capture
      # TODO: are there any scenarios where we need to cast to_f before output?
      obj.to_f.to_s
    else
      Liquid2.to_s(obj)
    end
  end

  def self.to_liquid_int(obj, default: 0)
    Float(obj).to_i
  rescue ArgumentError, TypeError
    default
  end

  # Return `true` if _obj_ is Liquid truthy.
  # @param context [RenderContext]
  # @param obj [Object]
  # @return [bool]
  def self.truthy?(context, obj)
    return false if context.env.falsy_undefined && undefined?(obj)

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
