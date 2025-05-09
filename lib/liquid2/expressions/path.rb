# frozen_string_literal: true

require_relative "../expression"

module Liquid2
  # A path to some variable data.
  # If the path has just one segment, it is often just called a "variable".
  class Path < Expression
    attr_reader :segments, :head

    RE_PROPERTY = /\A[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*\Z/

    # @param segments [Array[String | Integer | Path]]
    def initialize(token, segments)
      super(token)
      @segments = segments
      @head = @segments.shift
    end

    def evaluate(context)
      context.fetch(@head, @segments, node: self)
    end

    def to_s
      segment_to_s(@head, head: true) + @segments.map { |segment| segment_to_s(segment) }.join
    end

    def children
      if @head.is_a?(Path)
        [@head, *@segments.filter { |segment| segment.is_a?(Path) }]
      else
        @segments.filter { |segment| segment.is_a?(Path) }
      end
    end

    private

    def segment_to_s(segment, head: false)
      if segment.is_a?(String)
        if segment.match?(RE_PROPERTY)
          "#{head ? "" : "."}#{segment}"
        else
          "[#{segment.inspect}]"
        end
      else
        "[#{segment}]"
      end
    end
  end
end
