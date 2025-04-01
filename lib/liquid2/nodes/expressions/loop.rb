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

    def evaluate(context)
      # TODO:
    end

    protected

    def to_enum(context, obj)
      # TODO:
    end
  end
end
