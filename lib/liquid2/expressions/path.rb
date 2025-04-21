# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # A path to some variable data.
  # If the path has just one segment, it is often just called a "variable".
  class Path < Expression
    attr_reader :segments, :head

    # @param segments [Array[String | Integer | Path]]
    def initialize(token, segments)
      super(token)
      @segments = segments
      @head = @segments.shift
    end

    def evaluate(context)
      context.fetch(@head, @segments, node: self)
    end

    # TODO: fix and optimize
    def to_s = @head.to_s + @segments.map(&:to_s).join
  end
end
