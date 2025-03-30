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

    def evaluate(context)
      context.fetch(@segments.map { |segment| segment.evaluate(context) }, token: @children.first)
    end
  end

  # Paths are composed of segments..
  class PathSegment < Expression
    attr_reader :selector

    # @param children [Array<Node, Token>]
    # @param selector [Node, Token]
    def initialize(children, selector)
      super(children)
      @selector = if selector.is_a?(Token)
                    # Integer or shorthand name
                    selector.kind == :token_int ? Liquid2.to_i(selector.text) : selector.text
                  else
                    # Quoted string or path
                    selector
                  end
    end
  end

  class BracketedSegment < PathSegment
    def evaluate(context)
      @selector.evaluate(context)
    end
  end

  class ShorthandSegment < PathSegment
    def evaluate(_context)
      @selector
    end
  end
end
