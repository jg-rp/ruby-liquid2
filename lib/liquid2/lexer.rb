# frozen_string_literal: true

require "set"
require "strscan"
require_relative "token"

module Liquid2
  # Return an array of tokens for the Liquid template _source_.
  # @param source [String] Liquid template source text.
  # @return [Array<Token>]
  def self.tokenize(source)
    lexer = Lexer.new(source)
    lexer.run
    lexer.tokens
  end

  # Lexical scanner for Liquid2 templates.
  class Lexer # rubocop:disable Metrics/ClassLength
    RE_WHITESPACE = /[ \n\r\t]+/
    RE_WHITESPACE_CONTROL = /[+\-~]/
    RE_WORD = /[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*/
    RE_INT  = /-?\d+(?:[eE]\+?\d+)?/
    RE_FLOAT = /((?:-?\d+\.\d+(?:[eE][+-]?\d+)?)|(-?\d+[eE]-\d+))/

    # `{# comment text #}` style comment
    RE_COMMENT = /
      (?<START>\{(?<HASHES0>\u0023+))   # Curly bracket followed by any number of hashes
      (?<WC0>[+\-~]?)                   # Whitespace control
      (?<TEXT>.*?)                      # Comment text
      (?<WC1>[+\-~]?)                   # Whitespace control
      (?<END>(?<HASHES1>\k<HASHES0>)\}) # Matching number of hashes and curly bracket.
    /mx

    # Make sure shorter symbols appear after longer symbols that share a prefix.
    RE_PUNCTUATION = /\?|\[|\]|\|{1,2}|\.{1,2}|,|:|\(|\)|<[=>]?|>=?|=[=>]?|!=?/

    S_QUOTES = Set["'", '"']

    # Keywords and symbols that get their own token kind.
    TOKEN_MAP = {
      "true" => :token_true,
      "false" => :token_false,
      "nil" => :token_nil,
      "null" => :token_nil,
      "and" => :token_and,
      "or" => :token_or,
      "not" => :token_not,
      "in" => :token_in,
      "contains" => :token_contains,
      "if" => :token_if,
      "else" => :token_else,
      "with" => :token_with,
      "required" => :token_required,
      "as" => :token_as,
      "for" => :token_for,
      "blank" => :token_blank,
      "empty" => :token_empty,
      "?" => :token_question,
      "[" => :token_lbracket,
      "]" => :token_rbracket,
      "|" => :token_pipe,
      "||" => :token_double_pipe,
      "." => :token_dot,
      ".." => :token_double_dot,
      "," => :token_comma,
      ":" => :token_colon,
      "(" => :token_lparen,
      ")" => :token_rparen,
      "=" => :token_assign,
      "<" => :token_lt,
      "<=" => :token_le,
      "<>" => :token_lg,
      ">" => :token_gt,
      ">=" => :token_ge,
      "==" => :token_eq,
      "!=" => :token_ne,
      "=>" => :token_arrow
    }.freeze

    attr_reader :tokens

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
      raise "empty span (#{kind}, #{value})" if @scanner.pos == @start

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

    def peek
      # Assumes we're peeking single byte characters.
      @scanner.peek(1)
    end

    # Advance the lexer if _pattern_ matches from the buffer position.
    # @return [String | nil]
    def accept(pattern)
      @scanner.scan(pattern)
    end

    # Consume trivia (whitespace).
    def accept_trivia
      raise "must emit before accepting trivia" if @scanner.pos != @start

      if (trivia = @scanner.scan(RE_WHITESPACE))
        @trivia = trivia
        @start = @scanner.charpos
      else
        @trivia = ""
      end
    end

    # Accept and emit whitespace control.
    def accept_whitespace_control
      raise "must emit before accepting whitespace control" if @scanner.pos != @start

      if (value = @scanner.scan(RE_WHITESPACE_CONTROL))
        emit(:token_whitespace_control, value)
      end
    end

    # @return [Array<Symbol, String> | nil] An array with two items, token kind and
    # substring.
    def accept_expression_token
      return [:token_single_quote, "'"] if accept("'")
      return [:token_double_quote, '"'] if accept('"')

      # Must test for float before int
      if (value = accept(RE_FLOAT))
        return [:token_float, value]
      end

      if (value = accept(RE_INT))
        return [:token_int, value]
      end

      if (value = accept(RE_PUNCTUATION))
        return [TOKEN_MAP.fetch(value, :token_symbol), value]
      end

      if (value = accept(RE_WORD))
        [TOKEN_MAP.fetch(value, :token_word), value]
      end
    end

    # Accept and emit a `{# comment #}` style comment.
    def accept_comment
      return unless @scanner.scan(RE_COMMENT)

      # Working around the lack of MatchData when using StringScanner.
      # Note that this works because our named captures span the entire pattern.
      offset = @start
      groups = RE_COMMENT.names.to_h do |name|
        value = @scanner[name]
        index = offset
        offset += value.length
        [name, { value: value, index: index }]
      end

      comment_start = groups["START"]
      @tokens << Token.new(:token_comment_start,
                           comment_start[:index],
                           "",
                           comment_start[:value])

      wc0 = groups["WC0"]
      unless wc0[:value].empty?
        wc0_start = wc0[:index]
        wc0_end = wc0_start + wc0[:value].length
        @tokens << Token.new(:token_whitespace_control, wc0_start, "", wc0_end)
      end

      comment_text = groups["TEXT"]
      @tokens << Token.new(:token_comment,
                           comment_text[:index],
                           "",
                           comment_text[:value])

      wc1 = groups["WC1"]
      unless wc1[:value].empty?
        wc1_start = wc1[:index]
        wc1_end = wc1_start + wc1[:value].length
        @tokens << Token.new(:token_whitespace_control, wc1_start, "", wc1_end)
      end

      comment_end = groups["END"]
      @tokens << Token.new(:token_comment_end,
                           comment_end[:index],
                           "",
                           comment_end[:value])

      @start = @scanner.charpos
    end

    def lex_markup
      accept_comment

      if (value = accept(/\{\{/))
        emit(:token_output_start, value)
        accept_whitespace_control
        return :lex_expression
      end

      if (value = accept(/\{%/))
        emit(:token_tag_start, value)
        accept_whitespace_control

        accept_trivia
        if (tag_name = accept(/(?:[a-z][a-z_0-9]*|#)/))
          emit(:token_tag_name, tag_name)

          return case tag_name
                 when "#"
                   :lex_inside_inline_comment
                 when "comment"
                   :lex_block_comment
                 when "raw"
                   :lex_raw
                 # TODO: lex_line_statements
                 else
                   :lex_expression
                 end
        else
          # Missing or malformed tag name
          # Try to parse expr anyway
          return :lex_expression
        end
      end

      if (text = accept(/.+?(?=(\{\{|\{%|\{#+|\Z))/m))
        emit(:token_other, text)
        return :lex_markup
      end

      # End of input
      nil
    end

    def lex_expression
      unknown = false

      loop do
        accept_trivia
        if (kind, value = accept_expression_token)
          unknown = false
          emit(kind, value)
          scan_string(value) if S_QUOTES.member?(value)
        else
          accept_whitespace_control
          if accept(/%\}/)
            emit(:token_tag_end, "%}")
            return :lex_markup
          end

          if accept(/\}\}/)
            emit(:token_output_end, "}}")
            return :lex_markup
          end

          # Not the end of an expression

          # Two unknown tokens in a row?
          # Assume we're no longer inside a tag or output statement.
          return :lex_markup if unknown

          unknown_ch = self.next
          # End of input?
          return nil if unknown_ch == ""

          emit(:token_unknown, unknown_ch)
          unknown = true
        end
      end
    end

    def lex_inside_inline_comment
      if (comment_text = accept(/.+?(?=[+\-~]?%\}|\Z)/m))
        emit(:token_comment, comment_text)
      end

      accept_whitespace_control
      emit(:token_tag_end, "%}") if accept(/%\}/)
      :lex_markup
    end

    def lex_raw
      accept_trivia

      # TODO: handle unexpected expression

      accept_whitespace_control

      if accept(/%\}/)
        emit(:token_tag_end, "%}")
        # TODO: handle unexpected expression in endraw tag
        if (raw_text = accept(/.+?(?=(\{%[+\-~]?\s*endraw\s*[+\-~]?%\}|\Z))/m))
          emit(:token_raw, raw_text)
        end
      end

      :lex_markup
    end

    def lex_block_comment
      accept_trivia

      # TODO: handle unexpected expression

      accept_whitespace_control

      if accept(/%\}/)
        emit(:token_tag_end, "%}")
        # TODO: handle unexpected expression in endcomment tag
        if (comment_text = accept(/.+?(?=(\{%[+\-~]?\s*endcomment\s*[+\-~]?%\}|\Z))/m))
          emit(:token_comment, comment_text)
        end
      end

      :lex_markup
    end

    # Scan a string literal surrounded by _quote_.
    # Assumes the opening quote has already been consumed and emitted.
    def scan_string(quote)
      # Characters in the current substring.
      # We're using this to avoid slicing into the StringScanner.
      buffer = []

      if peek == quote
        self.next
        emit(quote == "'" ? :token_single_quote : :token_double_quote, quote)
        return
      end

      loop do
        if peek == "\\"
          # An escape sequence
          emit(:token_string, buffer.join) unless buffer.empty?
          buffer.clear
          buffer << self.next
          buffer << self.next # Two-character escape
          # TODO: consume more characters for \uXXXX sequences
          emit(:token_string_escape, buffer.join)
          buffer.clear
        end

        if @scanner.match?("${")
          emit(:token_string, buffer.join) unless buffer.empty?
          buffer.clear
          @scanner.pos += 2
          emit(:token_string_interpol, "${")

          # Consume and emit tokens up to `}`
          # Two unknown tokens in a row means we break out of the loop and
          # assume we're no longer inside an interpolated expression.
          unknown = false
          loop do
            accept_trivia
            if (kind, value = accept_expression_token)
              unknown = false
              emit(kind, value)
              scan_string(value) if S_QUOTES.member?(value)
            elsif accept("}")
              emit(:token_string_interpol_end, "}")
              break
            elsif unknown
              break
            else
              unknown = true
              unknown_ch = self.next
              emit(:token_unknown, unknown_ch)
            end
          end
          next
        end

        peeked = peek

        if peeked == quote
          emit(:token_string, buffer.join) unless buffer.empty?
          buffer.clear
          self.next
          emit(quote == "'" ? :token_single_quote : :token_double_quote, peeked)
          return
        end

        if peeked == "" && !buffer.empty?
          # Unclosed string literal
          emit(:token_string, buffer.join)
        end

        buffer << self.next
      end
    end
  end
end
