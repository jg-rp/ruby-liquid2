# frozen_string_literal: true

require_relative "utils/unescape"

module Liquid2
  # Liquid template source text lexical scanner.
  #
  # This is a single pass tokenizer. We support tag and output delimiters inside string
  # literals, so we must scan expressions as we go.
  #
  # We give comment and raw tags special consideration here.
  class Scanner
    attr_reader :tokens

    RE_MARKUP_START = /\{[\{%#]/
    RE_WHITESPACE = /[ \n\r\t]+/
    RE_LINE_SPACE = /[ \t]+/
    RE_WORD = /[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*/
    RE_INT  = /-?\d+(?:[eE]\+?\d+)?/
    RE_FLOAT = /((?:-?\d+\.\d+(?:[eE][+-]?\d+)?)|(-?\d+[eE]-\d+))/
    RE_PUNCTUATION = /\?|\[|\]|\|{1,2}|\.{1,2}|,|:|\(|\)|<[=>]?|>=?|=[=>]?|!=?/
    RE_SINGLE_QUOTE_STRING_SPECIAL = /[\\'\$]/
    RE_DOUBLE_QUOTE_STRING_SPECIAL = /[\\"\$]/

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

    def self.tokenize(source, scanner)
      lexer = new(source, scanner)
      lexer.run
      lexer.tokens
    end

    # @param source [String]
    # @param scanner [StringScanner]
    def initialize(source, scanner)
      @source = source
      @scanner = scanner
      @scanner.string = @source

      # A pointer to the start of the current token.
      @start = 0

      # Tokens are arrays of (kind, value, start index)
      @tokens = [] # : Array[[Symbol, String?, Integer]]
    end

    def run
      state = :lex_markup
      state = send(state) until state.nil?
    end

    protected

    # @param kind [Symbol]
    # @param value [String?]
    # @return void
    def emit(kind, value)
      # TODO: For debugging. Comment this out when benchmarking.
      raise "empty span (#{kind}, #{value})" if @scanner.pos == @start

      @tokens << [kind, value, @start]
      @start = @scanner.pos
    end

    def skip_trivia
      # TODO: For debugging. Comment this out when benchmarking.
      raise "must emit before skipping trivia" if @scanner.pos != @start

      @start = @scanner.pos if @scanner.skip(RE_WHITESPACE)
    end

    def skip_line_trivia
      # TODO: For debugging. Comment this out when benchmarking.
      raise "must emit before skipping line trivia" if @scanner.pos != @start

      @start = @scanner.pos if @scanner.skip(RE_LINE_SPACE)
    end

    def accept_whitespace_control
      # TODO: For debugging. Comment this out when benchmarking.
      raise "must emit before accepting whitespace control" if @scanner.pos != @start

      ch = @scanner.peek(1)

      case ch
      when "-", "+", "~"
        @scanner.pos += 1
        @tokens << [:token_whitespace_control, ch, @start]
        @start = @scanner.pos
        true
      else
        false
      end
    end

    def lex_markup
      case @scanner.scan(RE_MARKUP_START)
      when "{#"
        raise "TODO"
      when "{{"
        @tokens << [:token_output_start, nil, @start]
        @start = @scanner.pos
        accept_whitespace_control
        skip_trivia
        :lex_expression
      when "{%"
        @tokens << [:token_tag_start, nil, @start]
        @start = @scanner.pos
        accept_whitespace_control
        skip_trivia

        if (tag_name = @scanner.scan(/(?:[a-z][a-z_0-9]*|#)/))
          @tokens << [:token_tag_name, tag_name, @start]
          @start = @scanner.pos
          skip_trivia

          case tag_name
          when "#"
            :lex_inside_inline_comment
          when "comment"
            :lex_block_comment
          when "doc"
            :lex_doc
          when "raw"
            :lex_raw
          when "liquid"
            :lex_line_statements
          else
            :lex_expression
          end
        else
          # Missing or malformed tag name
          # Try to parse expr anyway
          :lex_expression
        end
      else
        if @scanner.skip_until(/\{[\{%#]/)
          @scanner.pos -= 2
          # TODO: benchmark byteslice range vs length
          @tokens << [:token_other, @source.byteslice(@start...@scanner.pos), @start]
          @start = @scanner.pos
          :lex_markup
        else
          @scanner.terminate
          if @start != @scanner.pos
            @tokens << [:token_other, @source.byteslice(@start...@scanner.pos), @start]
            @start = @scanner.pos
          end
          nil
        end
      end
    end

    def lex_expression
      # TODO: For debugging. Comment this out when benchmarking.
      raise "must emit before accepting an expression token" if @scanner.pos != @start

      loop do
        skip_trivia

        case @scanner.get_byte
        when "'"
          @start = @scanner.pos
          scan_string("'", :token_single_quote_string, RE_SINGLE_QUOTE_STRING_SPECIAL)
        when "\""
          @start = @scanner.pos
          scan_string("\"", :token_double_quote_string, RE_DOUBLE_QUOTE_STRING_SPECIAL)
        when nil
          # End of scanner. Unclosed expression or string literal.
          break
        else
          @scanner.pos -= 1
          if (value = @scanner.scan(RE_FLOAT))
            @tokens << [:token_float, value, @start]
            @start = @scanner.pos
          elsif (value = @scanner.scan(RE_INT))
            @tokens << [:token_int, value, @start]
            @start = @scanner.pos
          elsif (value = @scanner.scan(RE_PUNCTUATION))
            @tokens << [TOKEN_MAP[value] || raise, nil, @start]
            @start = @scanner.pos
          elsif (value = @scanner.scan(RE_WORD))
            @tokens << [TOKEN_MAP[value] || :token_word, value, @start]
            @start = @scanner.pos
          else
            break
          end
        end
      end

      accept_whitespace_control

      # Miro benchmarks show no performance gain using scan_byte and peek_byte over scan here.
      case @scanner.scan(/[\}%]\}/)
      when "}}"
        @tokens << [:token_output_end, nil, @start]
      when "%}"
        @tokens << [:token_tag_end, nil, @start]
      else
        # Unexpected token
        return nil if @scanner.eos?

        @tokens << [:token_unknown, @scanner.getch, @start]
      end

      @start = @scanner.pos
      :lex_markup
    end

    def lex_inside_inline_comment
      if @scanner.skip_until(/(-)?%\}/)
        @scanner.pos -= @scanner.captures&.first.nil? ? 2 : 3
        @tokens << [:token_comment, @source.byteslice(@start...@scanner.pos), @start]
        @start = @scanner.pos
      end

      accept_whitespace_control

      case @scanner.scan(/[\}%]\}/)
      when "}}"
        @tokens << [:token_output_end, nil, @start]
      when "%}"
        @tokens << [:token_tag_end, nil, @start]
      else
        # Unexpected token
        return nil if @scanner.eos?

        @tokens << [:token_unknown, @scanner.getch, @start]
      end

      @start = @scanner.pos
      :lex_markup
    end

    def lex_raw
      skip_trivia
      accept_whitespace_control

      case @scanner.scan(/[\}%]\}/)
      when "}}"
        @tokens << [:token_output_end, nil, @start]
        @start = @scanner.pos
      when "%}"
        @tokens << [:token_tag_end, nil, @start]
        @start = @scanner.pos
      end

      if @scanner.skip_until(/(\{%[+\-~]?\s*endraw\s*[+\-~]?%\})/)
        @scanner.pos -= @scanner.captures&.first&.length || raise
        @tokens << [:token_raw, @source.byteslice(@start...@scanner.pos), @start]
        @start = @scanner.pos
      end

      :lex_markup
    end

    def lex_block_comment
      skip_trivia
      accept_whitespace_control

      case @scanner.scan(/[\}%]\}/)
      when "}}"
        @tokens << [:token_output_end, nil, @start]
        @start = @scanner.pos
      when "%}"
        @tokens << [:token_tag_end, nil, @start]
        @start = @scanner.pos
      end

      # TODO: handle nested comment blocks?
      # TODO: handle raw tags inside comment blocks?

      if @scanner.skip_until(/(\{%[+\-~]?\s*endcomment\s*[+\-~]?%\})/)
        @scanner.pos -= @scanner.captures&.first&.length || raise
        @tokens << [:token_comment, @source.byteslice(@start...@scanner.pos), @start]
        @start = @scanner.pos
      end

      :lex_markup
    end

    def lex_doc
      skip_trivia
      accept_whitespace_control

      case @scanner.scan(/[\}%]\}/)
      when "}}"
        @tokens << [:token_output_end, nil, @start]
        @start = @scanner.pos
      when "%}"
        @tokens << [:token_tag_end, nil, @start]
        @start = @scanner.pos
      end

      if @scanner.skip_until(/(\{%[+\-~]?\s*enddoc\s*[+\-~]?%\})/)
        @scanner.pos -= @scanner.captures&.first&.length || raise
        @tokens << [:token_doc, @source.byteslice(@start...@scanner.pos), @start]
        @start = @scanner.pos
      end

      :lex_markup
    end

    def lex_line_statements
      # TODO: For debugging. Comment this out when benchmarking.
      raise "must emit before accepting an expression token" if @scanner.pos != @start

      skip_trivia # Leading newlines are OK

      if (tag_name = @scanner.scan(/(?:[a-z][a-z_0-9]*|#)/))
        @tokens << [:token_tag_start, nil, @start]
        @tokens << [:token_tag_name, tag_name, @start]
        @start = @scanner.pos

        # TODO: handle block comment
        if tag_name == "#" && @scanner.scan_until(/([\r\n]+|-?%\})/)
          @scanner.pos -= @scanner.captures&.first&.length || raise
          @tokens << [:token_comment, @source.byteslice(@start...@scanner.pos), @start]
          @start = @scanner.pos
          @tokens << [:token_tag_end, nil, @start]
          :lex_line_statements

        elsif tag_name == "comment" && @scanner.scan_until(/(endcomment)/)
          @tokens << [:token_tag_end, nil, @start]
          @scanner.pos -= @scanner.captures&.first&.length || raise
          @tokens << [:token_comment, @source.byteslice(@start...@scanner.pos), @start]
          @start = @scanner.pos
          :lex_line_statements
        else
          :lex_inside_line_statement
        end
      else
        accept_whitespace_control
        case @scanner.scan(/[\}%]\}/)
        when "}}"
          @tokens << [:token_output_end, nil, @start]
          @start = @scanner.pos
        when "%}"
          @tokens << [:token_tag_end, nil, @start]
          @start = @scanner.pos
        end

        :lex_markup
      end
    end

    def lex_inside_line_statement
      loop do
        skip_line_trivia

        case @scanner.get_byte
        when "'"
          @start = @scanner.pos
          scan_string("'", :token_single_quote_string, RE_SINGLE_QUOTE_STRING_SPECIAL)
        when "\""
          @start = @scanner.pos
          scan_string("\"", :token_double_quote_string, RE_DOUBLE_QUOTE_STRING_SPECIAL)
        when nil
          # End of scanner. Unclosed expression or string literal.
          break

        else
          @scanner.pos -= 1
          if (value = @scanner.scan(RE_FLOAT))
            @tokens << [:token_float, value, @start]
            @start = @scanner.pos
          elsif (value = @scanner.scan(RE_INT))
            @tokens << [:token_int, value, @start]
            @start = @scanner.pos
          elsif (value = @scanner.scan(RE_PUNCTUATION))
            @tokens << [TOKEN_MAP[value] || raise, nil, @start]
            @start = @scanner.pos
          elsif (value = @scanner.scan(RE_WORD))
            @tokens << [TOKEN_MAP[value] || :token_word, value, @start]
            @start = @scanner.pos
          elsif @scanner.scan(/(\r?\n)+/)
            # End of the line statement
            @tokens << [:token_tag_end, nil, @start]
            @start = @scanner.pos
            return :lex_line_statements
          else
            # End of the line statement and enclosing `liquid` tag.
            @tokens << [:token_tag_end, nil, @start]
            accept_whitespace_control
            case @scanner.scan(/[\}%]\}/)
            when "}}"
              @tokens << [:token_output_end, nil, @start]
              @start = @scanner.pos
            when "%}"
              @tokens << [:token_tag_end, nil, @start]
              @start = @scanner.pos
            end

            return :lex_markup
          end
        end
      end
    end

    # Scan a string literal surrounded by single quotes.
    # Assumes the opening quote has already been consumed and emitted.
    def scan_string(quote, symbol, pattern)
      needs_unescaping = false

      loop do
        @scanner.pos -= 1 if @scanner.skip_until(pattern)
        case @scanner.get_byte
        when quote
          token = [symbol, @source.byteslice(@start...@scanner.pos - 1), @start] # : [Symbol, String, Integer]
          token[1] = Liquid2.unescape_string(token[1], quote, token) if needs_unescaping
          @tokens << token
          @start = @scanner.pos
          needs_unescaping = false
          return
        when "\\"
          # An escape sequence. Move past the next character.
          @scanner.get_byte
          needs_unescaping = true
        when "$"
          next unless @scanner.peek(1) == "{"

          # The start of a `${` expression.
          # Emit what we have so far. This could be empty if the template string
          # starts with `${`.
          token = [symbol, @source.byteslice(@start...@scanner.pos - 1), @start] # : [Symbol, String, Integer]
          token[1] = Liquid2.unescape_string(token[1], quote, token) if needs_unescaping
          @tokens << token

          @start = @scanner.pos
          needs_unescaping = false

          # Emit and move past `${`
          @tokens << [:token_string_interpol_start, nil, @start]
          @scanner.pos += 1
          @start = @scanner.pos

          loop do
            skip_trivia

            case @scanner.get_byte
            when "'"
              @start = @scanner.pos
              scan_string("'", :token_single_quote_string, RE_SINGLE_QUOTE_STRING_SPECIAL)
            when "\""
              @start = @scanner.pos
              scan_string("\"", :token_double_quote_string, RE_DOUBLE_QUOTE_STRING_SPECIAL)
            when "}"
              @tokens << [:token_string_interpol_end, nil, @start]
              @start = @scanner.pos
              break
            when nil
              # End of scanner. Unclosed expression or string literal.
              break
            else
              @scanner.pos -= 1
              if (value = @scanner.scan(RE_FLOAT))
                @tokens << [:token_float, value, @start]
                @start = @scanner.pos
              elsif (value = @scanner.scan(RE_INT))
                @tokens << [:token_int, value, @start]
                @start = @scanner.pos
              elsif (value = @scanner.scan(RE_PUNCTUATION))
                @tokens << [TOKEN_MAP[value] || raise, nil, @start]
                @start = @scanner.pos
              elsif (value = @scanner.scan(RE_WORD))
                @tokens << [TOKEN_MAP[value] || :token_word, value, @start]
                @start = @scanner.pos
              else
                break
              end
            end
          end
        when nil
          # End of scanner. Unclosed string literal.
          token = [symbol, @source.byteslice(@start...@scanner.pos - 1), @start] # : [Symbol, String, Integer]
          token[1] = Liquid2.unescape_string(token[1], quote, token) if needs_unescaping
          @tokens << token
          @start = @scanner.pos
          return
        end
      end
    end
  end
end
