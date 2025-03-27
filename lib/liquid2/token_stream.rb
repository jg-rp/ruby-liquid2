# frozen_string_literal: true

require_relative "node"
require_relative "token"

module Liquid2
  # Step through a stream of tokens.
  class TokenStream
    def initialize(tokens, mode: :strict)
      @tokens = tokens
      @mode = mode
      @pos = 0
      @eof = Token.new(:token_eof, @tokens.length, "", "")
    end

    def current
      @tokens[@pos] || @eof
    end

    def next
      if (token = @tokens[@pos])
        @pos += 1
        token
      else
        @eof
      end
    end

    def peek(offset = 1)
      @tokens[@pos + offset] || @eof
    end

    # Consume the next token if its kind matches _kind_.
    # @param kind [Symbol]
    # @return [Token] The next token or a `MissingToken`.
    def eat(kind)
      token = current
      if token.kind == kind
        @pos += 1
        token
      else
        raise "expected #{kind}, found #{token.kind}" if @mode == :strict

        MissingToken.new(:token_missing, token.start, "", "", kind)
      end
    end

    # Consume the next token if it is whitespace control.
    # @return [Token] The next token or an empty _default whitespace control_ token.
    def eat_whitespace_control
      token = current
      if token.kind == :token_whitespace_control
        @pos += 1
        token
      else
        Token.new(:token_default_whitespace_control, token.start, "", "")
      end
    end

    # @param kind [Set<Symbol>] a set of token kinds that cause us to stop skipping.
    # @return [Array<Token> | nil] the skipped tokens or nil if no tokens were skipped.
    def skip_until(kinds, max: 10)
      tokens = []
      loop do
        token = current
        if kinds.member?(token.kind) || tokens.length >= max || token.kind == :token_eof
          return tokens.empty? ? nil : tokens
        end

        tokens << self.next
      end
    end

    # @param reason [String] a string describing the expected token.
    # @return [Node] a new Missing node.
    def missing(reason)
      raise "expected #{reason}, found #{current.kind}" if @mode == :strict

      Missing.new([Token.new(:token_missing, current.start, "", "")])
    end
  end
end
