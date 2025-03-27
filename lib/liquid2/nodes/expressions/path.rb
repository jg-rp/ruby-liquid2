# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # A path to some variable data.
  # If the path has just one segment, it is often just called a "variable".
  class Path < Expression
    attr_reader :segments

    # @param segments [Array<PathSegment>]
    def initialize(segments)
      super
      @segments = segments
    end
  end

  # Paths are composed of segments..
  class PathSegment < Expression
    attr_reader :selector

    # @param children [Array<Node, Token>]
    # @param selector [Node, Token]
    def initialize(children, selector)
      super(children)
      @selector = selector
    end
  end

  class BracketedSegment < PathSegment
  end

  class ShorthandSegment < PathSegment
  end
end
