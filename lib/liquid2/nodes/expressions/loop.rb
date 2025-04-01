# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class LoopExpression < Expression
    attr_reader :identifier, :enum, :limit, :offset, :reversed, :cols

    def initialize(children, identifier, enum, limit: nil, offset: nil, reversed: false, cols: nil)
      super(children)
      @identifier = identifier
      @enum = enum
      @limit = limit
      @offset = offset
      @reversed = reversed
      @cols = cols
    end

    # @return [[Enumerator, Integer]] An enumerator and its length.
    def evaluate(context)
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

      stop = Liquid2.to_i((@limit || raise).evaluate(context)) + start if @limit
      obj = @enum.evaluate(context)

      if obj.respond_to?(:slice) && !obj.is_a?(String)
        array = stop ? obj.slice(start...stop) : obj.slice(start..)
        return [array.to_enum, array.size]
      end

      # TODO: optionally enable string iteration
      enum, length = if obj.is_a?(String)
                       obj.empty? ? [Enumerator.new {}, 0] : [[obj].to_enum, 1]
                     elsif obj.respond_to?(:each)
                       [obj.each, obj.size]
                     else
                       [Enumerator.new {}, 0]
                     end

      # TODO: set stop_index
      [lazy_slice(enum, start, stop), length]
    end

    protected

    def lazy_slice(enum, start_index, stop_index = nil)
      sliced = enum.lazy.drop(start_index)
      sliced = sliced.take(stop_index - start_index + 1) if stop_index
      sliced
    end
  end
end
