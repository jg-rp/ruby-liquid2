# frozen_string_literal: true

module Liquid2
  # Tokens are produced by the lexer and consumed by the parser. They represent
  # a substring in template source text along with a token kind.
  class Token
    attr_reader :kind, :start, :trivia, :text

    def initialize(kind, start, trivia, text)
      @kind = kind
      @start = start
      @trivia = trivia
      @text = text
    end

    def ==(other)
      self.class == other.class &&
        @kind == other.kind &&
        @start == other.start &&
        @trivia == other.trivia &&
        @text == other.text
    end

    alias eql? ==

    def hash
      [@kind, @text].hash
    end

    def full_start
      @start - @trivia.length
    end

    def full_text
      @trivia + @text
    end

    def width
      @text.length
    end

    def full_width
      @trivia.length + @text.length
    end

    def end
      full_start + @trivia.length + @text.length
    end
  end

  class MissingToken < Token
    attr_reader :missing_kind

    def initialize(kind, start, trivia, text, missing_kind)
      super(kind, start, trivia, text)
      @missing_kind = missing_kind
    end
  end
end
