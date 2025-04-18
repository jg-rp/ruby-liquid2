# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  class LoopExpression < Expression
    attr_reader :identifier, :enum, :limit, :offset, :reversed, :cols

    def initialize(token, identifier, enum, limit: nil, offset: nil, reversed: false, cols: nil)
      super(token)
      @identifier = identifier
      @enum = enum
      @limit = limit
      @offset = offset
      @reversed = reversed
      @cols = cols
    end

    # @return [[Enumerator, Integer]] An enumerator and its length.
    def evaluate(context)
      obj = @enum.evaluate(context)

      # TODO: optionally enable string iteration
      enum, length = if obj.is_a?(String)
                       [obj.each_char, obj.length]
                     elsif obj.respond_to?(:each)
                       [obj.each, obj.size]
                     else
                       [Enumerator.new {}, 0]
                     end

      offset_key = "#{@identifier.name}-#{@enum.text}"

      start = if @offset
                offset = (@offset || raise).evaluate(context)
                if offset == "continue"
                  context.stop_index(offset_key)
                else
                  Liquid2.to_i(offset)
                end
              else
                0
              end

      stop = @limit ? Liquid2.to_i((@limit || raise).evaluate(context)) + start : length

      context.stop_index(offset_key, index: stop)

      if obj.respond_to?(:slice) && !obj.is_a?(String) && !obj.is_a?(Hash)
        array = stop ? obj.slice(start...stop) : obj.slice(start..)
        array = array.reverse if @reversed
        return [array.to_enum, array.size]
      end

      [lazy_slice(enum, start, stop), length]
    end

    protected

    def lazy_slice(enum, start_index, stop_index = nil)
      sliced = enum.lazy.drop(start_index)
      sliced = sliced.take(stop_index - start_index) if stop_index
      @reversed ? sliced.to_a.reverse : sliced
    end
  end
end
