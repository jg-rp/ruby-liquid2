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

    RE_LINE_SPACE = /[ \t]+/
    RE_WORD = /[\u0080-\uFFFFa-zA-Z_][\u0080-\uFFFFa-zA-Z0-9_-]*/
    RE_INT  = /-?\d+(?:[eE]\+?\d+)?/
    RE_FLOAT = /((?:-?\d+\.\d+(?:[eE][+-]?\d+)?)|(-?\d+[eE]-\d+))/
    RE_PUNCTUATION = /\?|\[|\]|\|{1,2}|\.{1,2}|,|:|\(|\)|[<>=!]+/
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
      @tokens << [kind, value, @start]
      @start = @scanner.pos
    end

    def skip_trivia
      @start = @scanner.pos if @scanner.skip(/[ \n\r\t]+/)
    end

    def skip_line_trivia
      @start = @scanner.pos if @scanner.skip(RE_LINE_SPACE)
    end

    def accept_whitespace_control
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
      case @scanner.scan(/\{[\{%#]/)
      when "{#"
        :lex_comment
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

          case tag_name
          when "#"
            # Don't skip trivia for inline comments.
            # This is for consistency with other types of comments that include
            # leading whitespace.
            :lex_inside_inline_comment
          when "comment"
            skip_trivia
            :lex_block_comment
          when "doc"
            skip_trivia
            :lex_doc
          when "raw"
            skip_trivia
            :lex_raw
          when "liquid"
            skip_trivia
            :lex_line_statements
          else
            skip_trivia
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
      loop do
        skip_trivia
        if (value = @scanner.scan(RE_FLOAT))
          @tokens << [:token_float, value, @start]
          @start = @scanner.pos
        elsif (value = @scanner.scan(RE_INT))
          @tokens << [:token_int, value, @start]
          @start = @scanner.pos
        elsif (value = @scanner.scan(RE_PUNCTUATION))
          @tokens << [TOKEN_MAP[value] || :token_unknown, value, @start]
          @start = @scanner.pos
        elsif (value = @scanner.scan(RE_WORD))
          @tokens << [TOKEN_MAP[value] || :token_word, value, @start]
          @start = @scanner.pos
        else
          case @scanner.get_byte
          when "'"
            @start = @scanner.pos
            scan_string("'", :token_single_quote_string, RE_SINGLE_QUOTE_STRING_SPECIAL)
          when "\""
            @start = @scanner.pos
            scan_string("\"", :token_double_quote_string, RE_DOUBLE_QUOTE_STRING_SPECIAL)
          else
            @scanner.pos -= 1
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

        if (ch = @scanner.scan(/[\}%]/))
          raise LiquidSyntaxError.new("missing \"}\" or \"%\" detected",
                                      [:token_unknown, ch, @start])
        end

        @tokens << [:token_unknown, @scanner.getch, @start]
      end

      @start = @scanner.pos
      :lex_markup
    end

    def lex_comment
      hash_count = 1

      if (hashes = @scanner.scan(/#+/))
        hash_count += hashes.length
      end

      @tokens << [:token_comment_start, @source.byteslice(@start...@scanner.pos), @start]
      @start = @scanner.pos

      wc = accept_whitespace_control

      if @scanner.skip_until(/([+\-~]?)(\#{#{hash_count}}\})/)
        @scanner.pos -= @scanner[0]&.length || 0
        @tokens << [:token_comment, @source.byteslice(@start...@scanner.pos), @start]
        @start = @scanner.pos

        if (ch = @scanner[1]) && !ch.empty?
          @tokens << [:token_whitespace_control, ch, @start]
          @start = @scanner.pos += 1
        end

        if (end_comment = @scanner[2])
          @scanner.pos += end_comment.length
          @tokens << [:token_comment_end, @source.byteslice(@start...@scanner.pos), @start]
          @start = @scanner.pos
        end
      else
        # Fix the last one or two emitted tokens. They are not the start of a comment.
        @tokens.pop if wc
        @tokens.pop
        start = (@tokens.pop || raise).last
        @tokens << [:token_other, @source.byteslice(start...@scanner.pos), start]
      end

      :lex_markup
    end

    def lex_inside_inline_comment
      if @scanner.skip_until(/([+\-~])?%\}/)
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

      comment_depth = 1
      raw_depth = 0

      loop do
        unless @scanner.skip_until(/(\{%[+\-~]?\s*(comment|raw|endcomment|endraw)\s*[+\-~]?%\})/)
          break
        end

        tag_name = @scanner.captures&.last || raise

        case tag_name
        when "comment"
          comment_depth += 1
        when "raw"
          raw_depth += 1
        when "endraw"
          raw_depth -= 1 if raw_depth.positive?
        when "endcomment"
          next if raw_depth.positive?

          comment_depth -= 1
          next if comment_depth.positive?

          @scanner.pos -= @scanner.captures&.first&.length || raise
          @tokens << [:token_comment, @source.byteslice(@start...@scanner.pos), @start]
          @start = @scanner.pos
          break
        else
          raise "unreachable"
        end
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
      skip_trivia # Leading newlines are OK

      if (tag_name = @scanner.scan(/(?:[a-z][a-z_0-9]*|#)/))
        @tokens << [:token_tag_start, nil, @start]
        @tokens << [:token_tag_name, tag_name, @start]
        @start = @scanner.pos

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
      start_of_string = @start - 1
      needs_unescaping = false

      loop do
        @scanner.pos -= 1 if @scanner.skip_until(pattern)
        case @scanner.get_byte
        when quote
          # @type var token: [Symbol, String, Integer]
          token = [symbol, @source.byteslice(@start...@scanner.pos - 1) || raise, @start]
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
          # @type var token: [Symbol, String, Integer]
          token = [symbol, @source.byteslice(@start...@scanner.pos - 1) || raise, @start]
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
              raise LiquidSyntaxError.new("unclosed string literal or template string expression",
                                          [symbol, nil, start_of_string])
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
          raise LiquidSyntaxError.new("unclosed string literal or template string expression",
                                      [symbol, nil, start_of_string])
        end
      end
    end
  end
end
