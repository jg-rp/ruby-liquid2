# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # An expression used by the standard `for` and `tablerow` tags.
  class LoopExpression < Expression
    attr_reader :identifier, :enum, :limit, :offset, :reversed, :cols, :name

    EMPTY_ENUM = [].freeze # steep:ignore

    def initialize(token, identifier, enum, limit: nil, offset: nil, reversed: false, cols: nil)
      super(token)
      @identifier = identifier
      @enum = enum
      @limit = limit
      @offset = offset
      @reversed = reversed
      @cols = cols
      @name = "#{@identifier.name}-#{@enum}"
    end

    # @return [[Enumerable, Integer]] An enumerable and its length.
    def evaluate(context)
      obj = context.evaluate(@enum)

      # @type var array: Array[untyped]
      array = if obj.is_a?(Array)
                obj
              elsif obj.is_a?(Hash)
                obj.to_a
              elsif obj.is_a?(Range)
                # TODO: special big range slicing
                obj.to_a
              elsif obj.is_a?(String)
                # TODO: optionally enable string iteration
                obj.each_char.to_a
              elsif obj.respond_to?(:each)
                # TODO: special lazy drop slicing
                # #each and #slice is our enumerable drop interface
                obj.each.to_a
              else
                EMPTY_ENUM
              end

      length = array.length

      # No slicing required
      return @reversed ? array.reverse : array if @offset.nil? && @limit.nil?

      start = if @offset
                offset = context.evaluate(@offset)
                if offset == "continue"
                  context.stop_index(@name)
                else
                  Liquid2.to_i(offset)
                end
              else
                0
              end

      stop = @limit ? Liquid2.to_i(context.evaluate(@limit)) + start : length
      context.stop_index(@name, index: stop)

      array = (stop ? array.slice(start...stop) : array.slice(start..)) || EMPTY_ENUM
      @reversed ? array.reverse! : array
    end
  end
end
