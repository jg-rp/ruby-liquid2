# frozen_string_literal: true

require "strscan"
require_relative "token"

module Liquid2
  # Lexical scanner for Liquid2 template text.
  class Lexer
    RE_WHITESPACE = /[ \n\r\t]+/
    RE_WHITESPACE_CONTROL = /[+\-~]/
    RE_WORD = /[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*/
    RE_INT  = /-?\d+(?:[eE]\+?\d+)?/
    RE_FLOAT = /((?:-?\d+\.\d+(?:[eE][+-]?\d+)?)|(-?\d+[eE]-\d+))/

    RE_COMMENT = /
      (?<START>\{(?<HASHES0>\u0023+))   # Curly bracket followed by any number of hashes
      (?<WC0>[+\-~]?)                   # Whitespace control
      (?<TEXT>.*?)                      # Comment text
      (?<WC1>[+\-~]?)                   # Whitespace control
      (?<END>(?<HASHES1>\k<HASHES0>)\}) # Matching number of hashes and curly bracket.
    /mx

    def initialize(source)
      @scanner = StringScanner.new(source)
      @start = 0
      @trivia = ""
      @tokens = []
    end

    def run
      state = :lex_markup
      state = send(state) until state.nil?
    end

    protected

    def emit(kind, value)
      return nil if @scanner.pos > @full_start

      token = Token.new(kind, @start, @trivia, value)
      @tokens << token
      @start = @scanner.charpos
      @trivia = ""
      token
    end

    def next
      @scanner.get_byte || ""
    end

    def ignore
      @start = @scanner.charpos
    end

    def backup
      # Assumes we're backing-up single byte characters.
      @scanner.pos -= 1
    end

    def peek
      # Assumes we're peeking single byte characters.
      @scanner.peek(1)
    end

    # Advance the lexer if _pattern_ matches from the current position.
    # @return [String | nil]
    def accept(pattern)
      @scanner.scan(pattern)
    end

    # Consume trivia (whitespace).
    # @return [String] substring or empty string
    def accept_trivia
      raise "must emit before accepting trivia" if @scanner.pos != @start

      @trivia = @scanner.scan(RE_WHITESPACE) || ""
    end

    # @return [String | nil]
    def accept_whitespace_control
      raise "must emit before accepting whitespace control" if @scanner.pos != @start

      @scanner.scan(RE_WHITESPACE_CONTROL)
    end

    # @return [Array<Symbol, String> | nil] An array with two items, token kind and substring.
    def accept_expression_token
    end
  end
end
