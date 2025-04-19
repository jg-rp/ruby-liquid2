# frozen_string_literal: true

require "set"
require "strscan"
require_relative "expression"
require_relative "node"
require_relative "nodes/comment"
require_relative "nodes/output"
require_relative "expressions/arguments"
require_relative "expressions/array"
require_relative "expressions/blank"
require_relative "expressions/boolean"
require_relative "expressions/filtered"
require_relative "expressions/identifier"
require_relative "expressions/logical"
require_relative "expressions/loop"
require_relative "expressions/path"
require_relative "expressions/relational"

module Liquid2
  # Liquid template parser.
  class Parser
    # Parse Liquid template text into a syntax tree.
    # @param source [String]
    # @return [Array[Node | String]]
    def self.parse(env, source, scanner: nil)
      new(env, Liquid2::Scanner.tokenize(source, scanner || StringScanner.new(""))).parse
    end

    # @param env [Environment]
    # @param tokens [Array[[Symbol, String?, Integer]]]
    def initialize(env, tokens)
      @env = env
      @tokens = tokens
      @pos = 0
      @eof = [:token_eof, nil, tokens.length]
      @whitespace_carry = nil
    end

    # Return the current token without advancing the pointer.
    # An EOF token is returned if there are no tokens left.
    def current = @tokens[@pos] || @eof

    # Return the kind of the current token without advancing the pointer.
    def current_kind = current.first

    # Return the next token and advance the pointer.
    def next
      if (token = @tokens[@pos])
        @pos += 1
        token
      else
        @eof
      end
    end

    # Return the kind of the next token and advance the pointer
    def next_kind = self.next.first

    def peek(offset = 1) = @tokens[@pos + offset] || @eof

    def peek_kind(offset = 1) = peek(offset).first

    def previous = @tokens[@pos - 1] || raise

    # Consume the next token if its kind matches _kind_, raise an error if it does not.
    # @param kind [Symbol]
    # @return [Token] The consumed token.
    def eat(kind)
      token = self.next
      unless token.first == kind
        raise LiquidSyntaxError.new("expected #{kind}, found #{token.first}", token)
      end

      token
    end

    # Consume the next token if its kind is in _kinds_, raise an error if it does not.
    # @param kind [Symbol]
    # @return [Token] The consumed token.
    def eat_one_of(*kinds)
      token = self.next
      unless kinds.include? token.first
        raise LiquidSyntaxError.new("expected #{kinds.first}, found #{token.first}", token)
      end

      token
    end

    # @param name [String]
    # @return The :token_tag_name token.
    def eat_empty_tag(name)
      eat(:token_tag_start)
      @pos += 1 if current_kind == :token_whitespace_control
      name_token = eat(:token_tag_name)

      unless name == name_token[1]
        raise LiquidSyntaxError.new(
          "expected tag #{name}, found #{name_token.first}:#{name_token[1]}", name_token
        )
      end

      eat(:token_tag_end)
      name_token
    end

    # Return `true` if we're at the start of a tag named _name_.
    # @param name [String]
    # @return [bool]
    def tag?(name)
      token = peek # Whitespace control or tag name
      token = peek(2) if token.first == :token_whitespace_control
      token.first == :token_tag_name && token[1] == name
    end

    # Return `true` if the current token is a word matching _text_.
    # @param text [String]
    # @return [bool]
    def word?(text)
      token = current
      token.first == :token_word && token[1] == text
    end

    # Return the next tag name without advancing the pointer.
    # Assumes the current token is :token_tag_start.
    # @return [String]
    def peek_tag_name
      token = current # Whitespace control or tag name
      token = peek if token.first == :token_whitespace_control
      unless token.first == :token_tag_name
        raise LiquidSyntaxError.new("missing tag name #{token}",
                                    token)
      end

      token[1] || raise
    end

    # Advance the pointer if the current token is a whitespace control token.
    def skip_whitespace_control
      @pos += 1 if current_kind == :token_whitespace_control
    end

    # Advance the pointer if the current token is a whitespace control token, and
    # remember the token's value for the next text node.
    def carry_whitespace_control
      return unless current_kind == :token_whitespace_control

      @whitespace_carry = self.next[0]
    end

    # @return [Array[Node | String]]
    def parse
      nodes = [] # : Array[Node | String]

      loop do
        kind, value = self.next
        # TODO: handle whitespace control
        @pos += 1 if current_kind == :token_whitespace_control

        case kind
        when :token_other
          nodes << (value || raise)
        when :token_output_start
          nodes << parse_output
        when :token_tag_start
          nodes << parse_tag
        when :token_comment_start
          raise "TODO"
          # nodes << parse_comment
        when :token_eof
          return nodes
        else
          raise LiquidSyntaxError.new("unexpected token", previous)
        end
      end
    end

    # Parse Liquid markup until we find a tag token in _end_block_.
    # @param end_block [responds to include?] An array or set of tag names that will
    #   indicate the end of the block.
    # @return [Block]
    def parse_block(end_block)
      token = current
      nodes = [] # : Array[Node | String]

      loop do
        kind, value = self.next
        # TODO: handle whitespace control
        @pos += 1 if current_kind == :token_whitespace_control

        case kind
        when :token_other
          nodes << (value || raise)
        when :token_output_start
          nodes << parse_output
        when :token_tag_start
          if end_block.include?(peek_tag_name)
            @pos -= 1
            break
          end

          nodes << parse_tag
        when :token_comment_start
          nodes << parse_comment
        when :token_eof
          # TODO: raise
          break
        else
          raise LiquidSyntaxError.new("unexpected token: #{token.inspect}", previous)
        end
      end

      Block.new(token, nodes)
    end

    # @return [FilteredExpression|TernaryExpression]
    def parse_filtered_expression
      token = current
      left = parse_primary
      filters = parse_filters if current_kind == :token_pipe
      filters ||= [] # : Array[Filter]
      expr = FilteredExpression.new(token, left, filters)

      if current_kind == :token_if
        parse_ternary_expression(expr)
      else
        expr
      end
    end

    # @return [LoopExpression]
    def parse_loop_expression
      identifier = parse_identifier
      @pos += 1 # in
      enum = parse_primary

      reversed = false
      offset = nil # : (Expression | nil)
      limit = nil # : (Expression | nil)
      cols = nil # : (Expression | nil)

      if current_kind == :token_comma
        unless LOOP_KEYWORDS.member?(peek[1] || raise)
          enum = parse_array_literal(enum)
          return LoopExpression.new(identifier.token, identifier, enum,
                                    limit: limit, offset: offset, reversed: reversed, cols: cols)
        end

        # A comma between the iterable and the first argument is OK.
        @pos += 1 if current_kind == :token_comma
      end

      loop do
        token = self.next
        case token.first
        when :token_word
          case token[1]
          when "reversed"
            reversed = true
          when "limit"
            eat_one_of(:token_colon, :token_assign)
            limit = parse_primary
          when "cols"
            eat_one_of(:token_colon, :token_assign)
            cols = parse_primary
          when "offset"
            eat_one_of(:token_colon, :token_assign)
            offset_token = current
            offset = if offset_token.first == :token_word && offset_token[1] == "continue"
                       Identifier.new(self.next)
                     else
                       parse_primary
                     end
          else
            raise LiquidSyntaxError.new("expected 'reversed', 'offset' or 'limit'", token)
          end
        when :token_comma
          @pos += 1
        else
          @pos -= 1
          break
        end
      end

      LoopExpression.new(identifier.token, identifier, enum,
                         limit: limit, offset: offset, reversed: reversed, cols: cols)
    end

    # Parse a _primary_ expression.
    # A primary expression is a literal, a path (to a variable), or a logical
    # expression composed of other primary expressions.
    # @return [Node]
    def parse_primary(precedence: Precedence::LOWEST)
      # Keywords followed by a dot or square bracket are parsed as paths.
      looks_like_a_path = %i[token_dot token_lbracket].include?(peek_kind)

      kind = current_kind

      left = case kind
             when :token_true
               self.next
               looks_like_a_path ? parse_path : true
             when :token_false
               self.next
               looks_like_a_path ? parse_path : false
             when :token_nil
               self.next
               looks_like_a_path ? parse_path : nil
             when :token_int
               Liquid2.to_liquid_int(self.next[1])
             when :token_float
               Float(self.next[1])
             when :token_blank
               looks_like_a_path ? parse_path : Blank.new(self.next)
             when :token_empty
               looks_like_a_path ? parse_path : Empty.new(self.next)
             when :token_single_quote_string, :token_double_quote_string
               # TODO: unescape
               self.next[1]
             when :token_word, :token_lbracket
               parse_path
             when :token_lparen
               parse_range_lambda_or_grouped_expression
             when :token_not
               parse_prefix_expression
             else
               raise LiquidSyntaxError.new("unexpected token #{current}", current)
             end

      loop do
        kind = current_kind
        break if kind == :token_eof || PRECEDENCES.fetch(kind, Precedence::LOWEST) < precedence
        return left unless BINARY_OPERATORS.member?(kind)

        left = parse_infix_expression(left)
      end

      left
    end

    # Parse a string literal without interpolation..
    # @return [String]
    # @raises [LiquidTypeError].
    def parse_string
      node = parse_primary
      raise LiquidTypeError, "expected a string" unless node.is_a?(String)

      node
    end

    def parse_identifier(trailing_question: true)
      Identifier.from(parse_primary, trailing_question: trailing_question)
    end

    # Parse comma separated expression.
    # Leading commas should be consumed by the caller.
    # @return [Array<PositionalArgument>]
    def parse_positional_arguments
      args = [] # : Array[PositionalArgument]

      loop do
        token = current
        item = parse_primary
        args << PositionalArgument.new(token, item)
        break unless current_kind == :token_comma

        @pos += 1
      end

      args
    end

    # Parse comma name/value pairs.
    # Leading commas should be consumed by the caller.
    # @return [Array<KeywordArgument>]
    def parse_keyword_arguments
      args = [] # : Array[KeywordArgument]

      loop do
        break unless current_kind == :token_word && KEYWORD_ARGUMENT_DELIMITERS.member?(peek_kind)

        word = self.next
        @pos += 1
        val = parse_primary
        args << KeywordArgument.new(word, word[1] || raise, val)
      end

      args
    end

    protected

    class Precedence
      LOWEST = 1
      LOGICAL_RIGHT = 2
      LOGICAL_OR = 3
      LOGICAL_AND = 4
      RELATIONAL = 5
      MEMBERSHIP = 6
      PREFIX = 7
    end

    PRECEDENCES = {
      token_and: Precedence::LOGICAL_AND,
      token_or: Precedence::LOGICAL_OR,
      token_not: Precedence::PREFIX,
      token_rparen: Precedence::LOWEST,
      token_contains: Precedence::MEMBERSHIP,
      token_eq: Precedence::RELATIONAL,
      token_lt: Precedence::RELATIONAL,
      token_gt: Precedence::RELATIONAL,
      token_ne: Precedence::RELATIONAL,
      token_lg: Precedence::RELATIONAL,
      token_le: Precedence::RELATIONAL,
      token_ge: Precedence::RELATIONAL
    }.freeze

    BINARY_OPERATORS = Set[
      :token_eq,
      :token_lt,
      :token_gt,
      :token_lg,
      :token_ne,
      :token_le,
      :token_ge,
      :token_contains,
      :token_and,
      :token_or
    ]

    TERMINATE_OUTPUT = Set[
      :token_whitespace_control,
      :token_output_end,
      :token_other,
      :token_line_term
    ]

    TERMINATE_FILTER = Set[
      :token_whitespace_control,
      :token_output_end,
      :token_tag_end,
      :token_pipe,
      :token_double_pipe,
      :token_if,
      :token_else,
      :token_other,
      :token_eof,
      :token_line_term
    ]

    TERMINATE_GROUPED_EXPRESSION = Set[
      :token_eof,
      :token_other,
      :token_rparen
    ]

    TERMINATE_LAMBDA_PARAM = Set[
      :token_rparen,
      :token_word,
      :token_comma,
      :token_arrow
    ]

    KEYWORD_ARGUMENT_DELIMITERS = Set[
      :token_assign,
      :token_colon
    ]

    PRIMITIVE_TOKENS = Set[
      :token_true,
      :token_false,
      :token_nil,
      :token_int,
      :token_float,
      :token_single_quote,
      :token_double_quote,
      :token_word,
      :token_lparen
    ]

    RESERVED_WORDS = Set[
      :token_true,
      :token_false,
      :token_nil,
      :token_and,
      :token_or,
      :token_not,
      :token_in,
      :token_contains,
      :token_if,
      :token_else,
      :token_with,
      :token_required,
      :token_as,
      :token_for,
      :token_blank,
      :token_empty,
    ]

    LOOP_KEYWORDS = Set[
      "limit",
      "reversed",
      "cols",
      "offset"
    ]

    WC_TOKENS = Set[
      :token_output_start,
      :token_comment_start,
      :token_tag_tags
    ]

    # @return [Output]
    def parse_output
      expr = parse_filtered_expression
      carry_whitespace_control
      eat(:token_output_end)
      Output.new(expr.token, expr)
    end

    # @return [Node]
    def parse_tag
      token = eat(:token_tag_name)

      if (tag = @env.tags[token[1] || raise])
        tag.parse(self)
      else
        raise LiquidSyntaxError.new("unknown tag #{token[0]}", token)
      end
    end

    # @return [Node]
    def parse_comment
      skip_whitespace_control
      token = eat(:token_comment)
      carry_whitespace_control
      eat(:token_comment_end)
      Comment.new(token, token[1] || raise)
    end

    # @return [Node]
    def parse_path
      token = current
      segments = [] # : Array[String | Integer | Path]

      segments << (self.next[1] || raise) unless current_kind == :token_lbracket

      loop do
        case self.next.first
        when :token_lbracket
          segments << parse_bracketed_path_selector
        when :token_dot
          segments << parse_shorthand_path_selector
        else
          @pos -= 1
          return Path.new(token, segments)
        end
      end
    end

    # @return [Node]
    def parse_bracketed_path_selector
      kind, value = self.next
      eat(:token_rbracket)

      case kind
      when :token_int
        value.to_i
      when :token_word
        parse_path
      when :token_double_quote_string, :token_single_quote_string
        # TODO: unescape
        value || raise
      else
        raise LiquidSyntaxError.new(
          "unexpected token in bracketed selector, #{current_kind}", current
        )
      end
    end

    # @return [Node]
    def parse_shorthand_path_selector
      kind, value = self.next
      case kind
      when :token_int
        value.to_i
      when :token_word
        value || raise
      else
        unless RESERVED_WORDS.member?(kind)
          raise LiquidSyntaxError.new("unexpected token in shorthand selector, #{kind}", previous)
        end

        value || raise
      end
    end

    # Parse a comma separated list of expressions. Assumes the next token is a comma.
    # @param left [Expression] The first item in the array.
    # @return [ArrayLiteral]
    def parse_array_literal(left)
      token = current
      items = [left] # : Array[untyped]

      loop do
        break unless current_kind == :token_comma

        break if TERMINATE_FILTER.member?(current_kind)

        items << parse_primary
      end

      # TODO: incorrect token
      ArrayLiteral.new(token, items)
    end

    # @return [Node]
    def parse_range_lambda_or_grouped_expression
      raise "TODO"
    end

    # @return [Node]
    def parse_prefix_expression
      token = eat(:token_not)
      expr = parse_primary
      LogicalNot.new(token, expr)
    end

    # @param left [Expression]
    # @return [Node]
    def parse_infix_expression(left)
      op_token = self.next
      precedence = PRECEDENCES.fetch(op_token.first, Precedence::LOWEST)
      right = parse_primary(precedence: precedence)

      case op_token.first
      when :token_eq
        Eq.new(left.token, left, right)
      when :token_lt
        Lt.new(left.token, left, right)
      when :token_gt
        Gt.new(left.token, left, right)
      when :token_ne, :token_lg
        Ne.new(left.token, left, right)
      when :token_le
        Le.new(left.token, left, right)
      when :token_ge
        Ge.new(left.token, left, right)
      when :token_contains
        Contains.new(left.token, left, right)
      when :token_and
        LogicalAnd.new(left.token, left, right)
      when :token_or
        LogicalOr.new(left.token, left, right)
      else
        raise LiquidSyntaxError.new("unexpected infix operator, #{op_token[1]}", op_token)
      end
    end

    # @return [Array<Filter>]
    def parse_filters
      filters = [parse_filter] # first filter could start with a double pipe
      filters << parse_filter while current_kind == :token_pipe
      filters
    end

    # @return [Filter]
    def parse_filter
      # @type var children: Array[Token | Node]
      @pos += 1 # pipe or double pipe
      name = eat(:token_word)

      unless current_kind == :token_colon || !TERMINATE_FILTER.member?(current_kind)
        # No arguments
        return Filter.new(name, name[1] || raise, []) # TODO: optimize
      end

      @pos += 1 # token_colon
      args = [] # : Array[PositionalArgument | KeywordArgument]

      loop do
        token = current
        case token.first
        when :token_word
          if KEYWORD_ARGUMENT_DELIMITERS.member?(peek_kind)
            # A keyword argument
            word = self.next
            @pos += 1 # sep
            val = parse_primary
            args << KeywordArgument.new(word, word[1] || raise, val)
          elsif peek_kind == :token_arrow
            # A positional argument that is an arrow function with a single parameter.
            args << PositionalArgument.new(token, parse_arrow_function)
          else
            # A positional argument that is a path.
            node = parse_path
            args << PositionalArgument.new(token, node)
          end
        when :token_lparen
          # A grouped expression or range or arrow function
          args << PositionalArgument.new(token, parse_primary)
        else
          break if TERMINATE_FILTER.member?(current_kind)

          args << PositionalArgument.new(token, parse_primary)
        end

        break if TERMINATE_FILTER.member?(current_kind)

        eat(:token_comma)
      end

      Filter.new(name, name[1] || raise, args)
    end

    # @return [Node]
    def parse_arrow_function
      raise "TODO"
    end

    # @param children [Array<Token | Node>] Child tokens already consumed by the caller.
    # @param expr [Expression] The first parameter already passed by the caller.
    # @return [Expression]
    def parse_partial_arrow_function(expr)
      raise "TODO"
    end

    # @param left [Expression]
    # @return [Node]
    def parse_ternary_expression(left)
      eat(:token_if)
      condition = BooleanExpression.new(current, parse_primary)
      alternative = nil # : Expression?
      filters = [] # : Array[Filter]
      tail_filters = [] # : Array[Filter]

      if current_kind == :token_else
        @pos += 1
        alternative = parse_primary
        filters = parse_filters if current_kind == :token_pipe
      end

      tail_filters = parse_filters if current_kind == :token_double_pipe

      TernaryExpression.new(left.token, left, condition, alternative, filters, tail_filters)
    end
  end
end
