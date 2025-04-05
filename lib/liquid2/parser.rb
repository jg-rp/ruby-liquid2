# frozen_string_literal: true

require "set"
require_relative "node"
require_relative "token_stream"
require_relative "nodes/comment"
require_relative "nodes/other"
require_relative "nodes/output"
require_relative "nodes/expressions/arguments"
require_relative "nodes/expressions/array"
require_relative "nodes/expressions/blank"
require_relative "nodes/expressions/boolean"
require_relative "nodes/expressions/lambda"
require_relative "nodes/expressions/filtered"
require_relative "nodes/expressions/identifier"
require_relative "nodes/expressions/literals"
require_relative "nodes/expressions/loop"
require_relative "nodes/expressions/logical"
require_relative "nodes/expressions/path"
require_relative "nodes/expressions/range"
require_relative "nodes/expressions/relational"
require_relative "nodes/expressions/string"

module Liquid2
  # Liquid template parser.
  class Parser
    # @param env [Environment]
    def initialize(env)
      @env = env
    end

    # Parse Liquid template text into an AST.
    # @param source [String]
    # @return [RootNode]
    def parse(source)
      nodes = [] # : Array[Node]
      stream = TokenStream.new(Liquid2.tokenize(source), mode: @env.mode)
      left_trim = :whitespace_control_default

      loop do
        token = stream.current
        case token.kind
        when :token_other
          text_token = stream.next
          nodes << Other.new([text_token], @env.trim(token.text, left_trim, peek_wc(stream)))
          left_trim = :whitespace_control_default
        when :token_output_start
          output_node = parse_output(stream)
          nodes << output_node
          left_trim = output_node.wc.last
        when :token_tag_start
          nodes << parse_tag(stream)
          left_trim = stream.trim_carry
        when :token_comment_start
          comment_node = parse_comment(stream)
          nodes << comment_node
          left_trim = comment_node.wc.last
        when :token_eof
          return RootNode.new(nodes)
        else
          raise LiquidSyntaxError.new("unexpected token: #{token.inspect}", token)
        end
      end
    end

    # Parse Liquid markup until we find a tag token in _end_block_.
    # @param stream [TokenStream]
    # @param end_block [responds to include?] An array or set of tag names that will
    #   indicate the end of the block.
    # @return [Block]
    def parse_block(stream, end_block)
      nodes = [] # : Array[Node]
      left_trim = stream.trim_carry

      loop do
        token = stream.current
        case token.kind
        when :token_other
          text_token = stream.next
          nodes << Other.new([text_token], @env.trim(token.text, left_trim, peek_wc(stream)))
          left_trim = :whitespace_control_default
        when :token_output_start
          output_node = parse_output(stream)
          nodes << output_node
          left_trim = output_node.wc.last
        when :token_tag_start
          break if end_block.include?(peek_tag_name(stream).text)

          nodes << parse_tag(stream)
          left_trim = stream.trim_carry
        when :token_comment_start
          comment_node = parse_comment(stream)
          nodes << comment_node
          left_trim = comment_node.wc.last
        when :token_eof
          # TODO: raise
          break
        else
          raise LiquidSyntaxError.new("unexpected token: #{token.inspect}", token)
        end
      end

      Block.new(nodes)
    end

    # Parse lines from a `liquid` tag.
    # @param stream [TokenStream]
    # @return [Block]
    def parse_line_statements(stream)
      nodes = [] # : Array[Node]

      loop do
        token = stream.current
        case token.kind
        when :token_tag_start
          nodes << parse_tag(stream)
        when :token_whitespace_control, :token_tag_end
          break
        else
          raise LiquidSyntaxError.new("unexpected token: #{token.inspect}", token)
        end
      end

      Block.new(nodes)
    end

    # @param stream [TokenStream]
    # @return [FilteredExpression|TernaryExpression]
    def parse_filtered_expression(stream)
      left = parse_primary(stream)
      left = parse_array_literal(stream, left) if stream.current.kind == :token_comma
      filters = parse_filters(stream) if stream.current.kind == :token_pipe
      filters ||= [] # : Array[Filter]
      expr = FilteredExpression.new([left, *filters], left, filters)

      if stream.current.kind == :token_if
        parse_ternary_expression(stream, expr)
      else
        expr
      end
    end

    # @param stream [TokenStream]
    # @return [LoopExpression]
    def parse_loop_expression(stream)
      identifier = parse_identifier(stream)
      # @type var children: Array[Token | Node]
      children = [identifier, stream.eat(:token_in)]
      enum = parse_primary(stream)
      children << enum

      reversed = false
      offset = nil # : (Expression | nil)
      limit = nil # : (Expression | nil)
      cols = nil # : (Expression | nil)

      if stream.current.kind == :token_comma
        # A comma between the iterable and the first argument is OK.
        children << stream.eat(:token_comma)
      end

      loop do
        token = stream.current
        case token.kind
        when :token_word
          case token.text
          when "reversed"
            children << stream.next
            reversed = true
          when "limit"
            children << stream.next << stream.eat_one_of(:token_colon, :token_assign)
            node = parse_primary(stream)
            children << node
            limit = node
          when "cols"
            children << stream.next << stream.eat_one_of(:token_colon, :token_assign)
            node = parse_primary(stream)
            children << node
            cols = node
          when "offset"
            children << stream.next << stream.eat_one_of(:token_colon, :token_assign)
            offset_token = stream.peek
            node = if offset_token.kind == :token_word && offset_token.text == "continue"
                     Identifier.new(stream.next)
                   else
                     parse_primary(stream)
                   end
            children << node
            offset = node
          else
            raise LiquidSyntaxError.new("expected 'reversed', 'offset' or 'limit'", token)
          end
        when :token_comma
          children << stream.next
        else
          break
        end
      end

      LoopExpression.new(children, identifier, enum,
                         limit: limit, offset: offset, reversed: reversed, cols: cols)
    end

    # Parse a _primary_ expression from tokens in _stream_.
    # A primary expression is a literal, a path (to a variable), or a logical
    # expression composed of other primary expressions.
    # @param stream [TokenStream]
    # @return [Node]
    def parse_primary(stream, precedence: Precedence::LOWEST)
      # Keywords followed by a dot or square bracket are parsed as paths.
      looks_like_a_path = %i[token_dot token_lbracket].include?(stream.peek.kind)

      left = case stream.current.kind
             when :token_true
               looks_like_a_path ? parse_path(stream) : TrueLiteral.new(stream.next)
             when :token_false
               looks_like_a_path ? parse_path(stream) : FalseLiteral.new(stream.next)
             when :token_nil
               looks_like_a_path ? parse_path(stream) : NilLiteral.new(stream.next)
             when :token_int
               IntegerLiteral.new(stream.next)
             when :token_float
               FloatLiteral.new(stream.next)
             when :token_blank
               looks_like_a_path ? parse_path(stream) : Blank.new(stream.next)
             when :token_empty
               looks_like_a_path ? parse_path(stream) : Empty.new(stream.next)
             when :token_single_quote, :token_double_quote
               parse_string_literal(stream)
             when :token_word, :token_lbracket
               parse_path(stream)
             when :token_lparen
               parse_range_lambda_or_grouped_expression(stream)
             when :token_not
               parse_prefix_expression(stream)
             else
               looks_like_a_path ? parse_path(stream) : stream.missing("expression")
             end

      loop do
        token = stream.current
        break if token.kind == :token_eof || PRECEDENCES.fetch(token.kind,
                                                               Precedence::LOWEST) < precedence

        return left unless BINARY_OPERATORS.member?(token.kind)

        left = parse_infix_expression(stream, left)
      end

      left
    end

    # Parse a string literal without interpolation from tokens in _stream_.
    # @param stream [TokenStream]
    # @return [StringLiteral]
    # @raises [LiquidTypeError] If there is no string at the front of the token stream.
    def parse_string(stream)
      node = parse_primary(stream)
      raise LiquidTypeError, "expected a string" unless node.is_a?(StringLiteral)

      node
    end

    def parse_identifier(stream, trailing_question: true)
      Identifier.from(parse_primary(stream), trailing_question: trailing_question)
    end

    # Parse a comma separated list of expressions. Assumes the next token is a comma.
    # @param stream [TokenStream]
    # @param left [Expression] The first item in the array.
    # @return [ArrayLiteral]
    def parse_array_literal(stream, left)
      children = [left] # : Array[Node | Token]
      items = [left] # : Array[Expression]

      loop do
        break unless stream.current.kind == :token_comma

        children << stream.next
        expr = parse_primary(stream)
        children << expr
        items << expr
      end

      ArrayLiteral.new(children, items)
    end

    # Parse comma separated expression from stream.
    # Leading commas should be consumed by the caller.
    # @param stream [TokenStream]
    # @return [Array<PositionalArgument>]
    def parse_positional_arguments(stream)
      args = [] # : Array[PositionalArgument]

      loop do
        item = parse_primary(stream)
        if stream.current.kind == :token_comma
          args << PositionalArgument.new([item, stream.eat(:token_comma)], item)
        else
          args << PositionalArgument.new([item], item)
          break
        end
      end

      args
    end

    # Parse comma name/value pairs from stream.
    # Leading commas should be consumed by the caller.
    # @param stream [TokenStream]
    # @return [Array<KeywordArgument>]
    def parse_keyword_arguments(stream)
      args = [] # : Array[KeywordArgument]

      loop do
        unless stream.current.kind == :token_word && KEYWORD_ARGUMENT_DELIMITERS.member?(stream.peek.kind)
          break
        end

        word = stream.next
        sep = stream.next
        val = parse_primary(stream)
        args << KeywordArgument.new([word, sep, val], word, val)
      end

      args
    end

    # Return the next tag name token from _stream_ without advancing.
    # Assumes the current token is :token_tag_start.
    def peek_tag_name(stream)
      token = stream.peek # Whitespace control or tag name
      token = stream.peek(2) if token.kind == :token_whitespace_control
      raise LiquidSyntaxError.new("missing tag name", token) unless token.kind == :token_tag_name

      token
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

    WC_TOKENS = Set[
      :token_output_start,
      :token_comment_start,
      :token_tag_tags
    ]

    def peek_wc(stream)
      token = stream.peek
      if token.kind == :token_whitespace_control
        Node::WC_MAP.fetch(token.text)
      else
        :whitespace_control_default
      end
    end

    # @param stream [TokenStream]
    # @return [Output]
    def parse_output(stream)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_output_start), stream.eat_whitespace_control]
      expr = parse_filtered_expression(stream)
      children << expr

      if (skipped = stream.skip_until(TERMINATE_OUTPUT))
        children << Skipped.new(skipped)
      end

      children << stream.eat_whitespace_control << stream.eat(:token_output_end)
      Output.new(children, expr)
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_tag(stream)
      token = peek_tag_name(stream)

      if (tag = @env.tags[token.text])
        tag.parse(stream, self)
      else
        raise LiquidSyntaxError.new("unknown tag #{token.text}", token)
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_comment(stream)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_comment_start), stream.eat_whitespace_control]
      token = stream.eat(:token_comment)
      children << token << stream.eat_whitespace_control << stream.eat(:token_comment_end)
      Comment.new(children, token)
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_string_literal(stream)
      quote_token = stream.next
      term = quote_token.kind # single or double

      # @type var children: Array[Token | Node]
      children = [quote_token]
      segments = [] # : Array[untyped]
      class_ = StringLiteral # : singleton(StringLiteral) | singleton(TemplateString)

      loop do
        case stream.current.kind
        when term
          children << stream.next
          return class_.new(children, segments)
        when :token_string, :token_string_escape
          token = stream.next
          children << token
          segments << StringSegment.new(token, quote_token.text)
        when :token_string_interpol
          class_ = TemplateString
          token = stream.next
          children << token
          node = parse_filtered_expression(stream)
          segments << node
          children << node << stream.eat(:token_string_interpol_end)
        else
          # unclosed string literal
          children << stream.eat(term)
          return class_.new(children, segments)
        end
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_path(stream)
      segments = [] # : Array[PathSegment]

      unless stream.current.kind == :token_lbracket
        token = stream.next
        segments << ShorthandSegment.new([token], token)
      end

      loop do
        case stream.current.kind
        when :token_lbracket
          segments << parse_bracketed_path_selector(stream)
        when :token_dot
          segments << parse_shorthand_path_selector(stream)
        else
          return Path.new(segments)
        end
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_bracketed_path_selector(stream)
      bracket_token = stream.eat(:token_lbracket)

      case stream.current.kind
      when :token_int
        selector = stream.next
        BracketedSegment.new([bracket_token, selector, stream.eat(:token_rbracket)], selector)
      when :token_word
        node = parse_path(stream)
        BracketedSegment.new([bracket_token, node, stream.eat(:token_rbracket)], node)
      when :token_double_quote, :token_single_quote
        node = parse_string_literal(stream)
        BracketedSegment.new([bracket_token, node, stream.eat(:token_rbracket)], node)
      else
        # TODO: or skip
        raise LiquidSyntaxError.new(
          "unexpected token in bracketed selector, #{stream.current.kind}", stream.current
        )
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_shorthand_path_selector(stream)
      dot = stream.eat(:token_dot)
      token = stream.next
      case token.kind
      when :token_int, :token_word
        # TODO: optionally disable shorthand indexes
        ShorthandSegment.new([dot, token], token)
      else
        # TODO: or skip
        unless RESERVED_WORDS.member?(token.kind)
          raise LiquidSyntaxError.new("unexpected token in shorthand selector, #{token.kind}",
                                      token)
        end

        ShorthandSegment.new([dot, token], token)
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_range_lambda_or_grouped_expression(stream)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_lparen)]
      expr = parse_primary(stream)

      token = stream.current

      if token.kind == :token_double_dot
        stream.next
        stop = parse_primary(stream)
        children << expr << token << stop << stream.eat(:token_rparen)
        return RangeExpression.new(children, expr, stop)
      end

      # An arrow function, but we've already consumed lparen and the first parameter.
      return parse_partial_arrow_function(stream, children, expr) if token.kind == :token_comma

      # An arrow function with a single parameter surrounded by parens.
      if token.kind == :token_rparen && stream.peek.kind == :token_arrow
        return parse_partial_arrow_function(stream, children, expr)
      end

      loop do
        break if TERMINATE_GROUPED_EXPRESSION.member?(token.kind)

        unless BINARY_OPERATORS.member?(token.kind)
          # TODO: or missing
          raise LiquidSyntaxError.new("expected an infix operator, found #{token.kind}", token)
        end

        expr = parse_infix_expression(stream, expr)
      end

      children << stream.eat(:token_rparen)
      GroupedExpression.new(children, expr)
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_prefix_expression(stream)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_not)]
      expr = parse_primary(stream)
      LogicalNot.new(children << expr, expr)
    end

    # @param stream [TokenStream]
    # @param left [Expression]
    # @return [Node]
    def parse_infix_expression(stream, left)
      op_token = stream.next
      precedence = PRECEDENCES.fetch(op_token.kind, Precedence::LOWEST)
      right = parse_primary(stream, precedence: precedence)
      children = [left, op_token, right]

      case op_token.kind
      when :token_eq
        Eq.new(children, left, right)
      when :token_lt
        Lt.new(children, left, right)
      when :token_gt
        Gt.new(children, left, right)
      when :token_ne, :token_lg
        Ne.new(children, left, right)
      when :token_le
        Le.new(children, left, right)
      when :token_ge
        Ge.new(children, left, right)
      when :token_contains
        Contains.new(children, left, right)
      when :token_and
        LogicalAnd.new(children, left, right)
      when :token_or
        LogicalOr.new(children, left, right)
      else
        # TODO:
        raise LiquidSyntaxError.new("unexpected infix operator, #{op_token.text}", op_token)
      end
    end

    # @param stream [TokenStream]
    # @return [Array<Filter>]
    def parse_filters(stream)
      filters = [parse_filter(stream)] # first filter could start with a double pipe
      filters << parse_filter(stream) while stream.current.kind == :token_pipe
      filters
    end

    # @param stream [TokenStream]
    # @return [Filter]
    def parse_filter(stream)
      # @type var children: Array[Token | Node]
      children = [stream.next] # pipe or double pipe
      name = stream.eat(:token_word)
      children << name

      unless stream.current.kind == :token_colon || !TERMINATE_FILTER.member?(stream.current.kind)
        return Filter.new(children,
                          name,
                          [])
      end

      children << stream.eat(:token_colon)
      args = [] # : Array[PositionalArgument | KeywordArgument]

      loop do
        case stream.current.kind
        when :token_word
          if KEYWORD_ARGUMENT_DELIMITERS.member?(stream.peek.kind)
            # A keyword argument
            word = stream.next
            sep = stream.next
            val = parse_primary(stream)
            arg = KeywordArgument.new([word, sep, val], word, val)
          elsif stream.peek.kind == :token_arrow
            # A positional argument that is an arrow function with a single parameter.
            node = parse_arrow_function(stream)
            arg = PositionalArgument.new([node], node)
          else
            # A positional argument that is a path.
            node = parse_path(stream)
            arg = PositionalArgument.new([node], node)
          end

          children << arg
          args << arg
        when :token_lparen
          # A a grouped expression or range or arrow function
          node = parse_primary(stream)
          arg = PositionalArgument.new([node], node)
          children << arg
          args << arg
        when :token_unknown
          return Filter.new(children, name, args) unless PRIMITIVE_TOKENS.member?(stream.peek.kind)

          # Probably still in a filter
          children << Skipped.new([stream.next])
        else
          return Filter.new(children, name, args) if TERMINATE_FILTER.member?(stream.current.kind)

          node = parse_primary(stream)
          arg = PositionalArgument.new([node], node)
          children << arg
          args << arg
        end

        return Filter.new(children, name, args) if TERMINATE_FILTER.member?(stream.current.kind)

        children << stream.eat(:token_comma)
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_arrow_function(stream)
      children = [] # : Array[Token | Node]
      params = [] # : Array[Identifier]

      case stream.current.kind
      when :token_word
        # A single parameter without parens
        token = stream.next
        param = Identifier.new(token)
        children << param
        params << param
      when :token_lparen
        # One or move parameters separated by commas and surrounded by parentheses.
        children << stream.next
        while stream.current.kind != :token_rparen
          token = stream.eat(:token_word)
          param = Identifier.new(token)
          children << param
          params << param

          children << stream.next if stream.current.kind == :token_comma

          unless TERMINATE_LAMBDA_PARAM.member?(stream.current.kind)
            children << Skipped.new([stream.next])
          end
        end

        children << stream.eat(:token_rparen)
      end

      children << stream.eat(:token_arrow)
      expr = parse_primary(stream)
      children << expr
      Lambda.new(children, params, expr)
    end

    # @param stream [TokenStream]
    # @param children [Array<Token | Node>] Child tokens already consumed by the caller.
    # @param expr [Expression] The first parameter already passed by the caller.
    # @return [Expression]
    def parse_partial_arrow_function(stream, children, expr)
      params = [] # : Array[Identifier]

      # expr should be a single segment path, we need an Identifier.
      param = Identifier.from(expr)
      params << param
      children << param
      children << stream.next if stream.current.kind == :token_comma

      while stream.current.kind != :token_rparen
        token = stream.eat(:token_word)
        param = Identifier.new(token)
        children << param
        params << param

        children << stream.next if stream.current.kind == :token_comma

        unless TERMINATE_LAMBDA_PARAM.member?(stream.current.kind)
          children << Skipped.new([stream.next])
          break
        end
      end

      children << stream.eat(:token_rparen)
      children << stream.eat(:token_arrow)
      expr = parse_primary(stream)
      children << expr
      Lambda.new(children, params, expr)
    end

    # @param stream [TokenStream]
    # @param left [Expression]
    # @return [Node]
    def parse_ternary_expression(stream, left)
      # @type var children: Array[Token | Node]
      children = [left, stream.eat(:token_if)]
      condition = BooleanExpression.new(parse_primary(stream))
      children << condition

      alternative = nil # : Expression?
      filters = [] # : Array[Filter]
      tail_filters = [] # : Array[Filter]

      if stream.current.kind == :token_else
        children << stream.next
        alternative = parse_primary(stream)
        children << alternative

        if stream.current.kind == :token_pipe
          filters = parse_filters(stream)
          children.push(*filters)
        end
      end

      if stream.current.kind == :token_double_pipe
        tail_filters = parse_filters(stream)
        children.push(*tail_filters)
      end

      TernaryExpression.new(children, left, condition, alternative, filters, tail_filters)
    end
  end
end
