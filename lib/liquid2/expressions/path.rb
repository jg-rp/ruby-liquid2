# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # A path to some variable data.
  # If the path has just one segment, it is often just called a "variable".
  class Path < Expression
    attr_reader :segments

    # @param segments [Array[String | Integer | Path]]
    def initialize(token, segments)
      super(token)
      @segments = segments
    end

    def evaluate(context)
      context.fetch(@segments.map do |segment|
        segment.is_a?(Path) ? segment.evaluate(context) : segment
      end, node: self)
    end

    # TODO: fix and optimize
    def to_s = @segments.map(&:to_s).join
  end
end
