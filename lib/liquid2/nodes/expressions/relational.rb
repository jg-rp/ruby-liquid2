# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  class Eq < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end
  end

  class Ne < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end
  end

  class Le < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end
  end

  class Ge < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end
  end

  class Lt < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end
  end

  class Gt < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end
  end

  class Contains < Expression
    # @param children [Array<Token, Node>]
    # @param left [Expression]
    # @param right [Expression]
    def initialize(children, left, right)
      super(children)
      @left = left
      @right = right
    end
  end
end
