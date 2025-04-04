# frozen_string_literal: true

require_relative "node"
require_relative "token"

module Liquid2
  # Step through a stream of tokens.
  class TokenStream
    attr_accessor :trim_carry

    def initialize(tokens, mode: :strict)
      @tokens = tokens
      @mode = mode
      @pos = 0
      @eof = Token.new(:token_eof, @tokens.length, "", "")
      @trim_carry = :whitespace_control_default
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
        if @mode == :strict
          raise LiquidSyntaxError.new("expected #{kind}, found #{token.kind}",
                                      token)
        end

        MissingToken.new(:token_missing, token.start, "", "", kind)
      end
    end

    # Consume the next token if its kind is in _kinds_.
    # @param kinds [Array<Symbol>]
    # @return [Token] The next token or a `MissingToken`.
    def eat_one_of(*kinds)
      token = current
      if kinds.include? token.kind
        @pos += 1
        token
      else
        if @mode == :strict
          raise LiquidSyntaxError.new("expected #{kinds.first}, found #{token.kind}",
                                      token)
        end

        MissingToken.new(:token_missing, token.start, "", "", kinds.first)
      end
    end

    # Consume the next token if it is whitespace control.
    # @return [Token] The next token or an empty _default whitespace control_ token.
    def eat_whitespace_control
      token = current
      if token.kind == :token_whitespace_control
        @pos += 1
        @trim_carry = Node::WC_MAP.fetch(token.text)
        token
      else
        @trim_carry = :whitespace_control_default
        Token.new(:token_whitespace_control, token.start, "", "")
      end
    end

    # Consume and return tokens for an empty tag (one without an expression), named with _name_.
    # @param name [String]
    # @return [Array<Token>]
    def eat_empty_tag(name)
      tokens = [eat(:token_tag_start), eat_whitespace_control]
      name_token = eat(:token_tag_name)

      unless name == name_token.text
        raise LiquidSyntaxError.new(
          "expected tag #{name}, found #{name_token.kind}:#{name_token.text}", name_token
        )
      end

      # TODO: handle tokens between end tag name and closing tag markup.
      tokens << name_token << eat_whitespace_control << eat(:token_tag_end)
    end

    # Return `true` if we're at the start of a tag named _name_.
    # @param name [String]
    # @return [bool]
    def tag?(name)
      token = peek # Whitespace control or tag name
      token = peek(2) if token.kind == :token_whitespace_control
      token.kind == :token_tag_name && token.text == name
    end

    # Return `true` if the current token is a word matching _text_.
    # @param text [String]
    # @return [bool]
    def word?(text)
      token = current
      token.kind == :token_word && token.text == text
    end

    # @param kind [Set<Symbol>] a set of token kinds that cause us to stop skipping.
    # @return [Array<Token> | nil] the skipped tokens or nil if no tokens were skipped.
    def skip_until(kinds, max: 10)
      tokens = [] # : Array[Token]
      loop do
        token = current
        if kinds.member?(token.kind) || tokens.length >= max || token.kind == :token_eof
          return nil if tokens.empty?
          if @mode == :strict
            raise LiquidSyntaxError.new("unexpected #{tokens.first.text.inspect}", tokens.first)
          end

          return tokens
        end

        tokens << self.next
      end
    end

    # @param reason [String] a string describing the expected token.
    # @return [Expression] a new Missing node.
    def missing(reason)
      if @mode == :strict
        raise LiquidSyntaxError.new("expected #{reason}, found #{current.kind}",
                                    current)
      end

      Missing.new([Token.new(:token_missing, current.start, "", "")],
                  "expected #{reason}, found #{current.kind}")
    end
  end
end
