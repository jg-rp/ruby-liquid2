# frozen_string_literal: true

require "set"
require_relative "node"
require_relative "token_stream"
require_relative "nodes/comment"
require_relative "nodes/other"
require_relative "nodes/output"
require_relative "nodes/expressions/arguments"
require_relative "nodes/expressions/boolean"
require_relative "nodes/expressions/filtered"
require_relative "nodes/expressions/identifier"
require_relative "nodes/expressions/lambda"
require_relative "nodes/expressions/literals"
require_relative "nodes/expressions/logical"
require_relative "nodes/expressions/path"
require_relative "nodes/expressions/range"
require_relative "nodes/expressions/relational"
require_relative "nodes/expressions/string"

module Liquid2
  class Parser
    # @param env [Environment]
    def initialize(env)
      @env = env
    end

    # Parse Liquid template text into an AST.
    # @param source [String]
    # @return [RootNode]
    def parse(source)
      nodes = []
      stream = TokenStream.new(Liquid2.tokenize(source), mode: @env.mode)

      loop do
        token = stream.current
        case token.kind
        when :token_other
          nodes << Other.new([stream.next], token.text)
        when :token_output_start
          nodes << parse_output(stream)
        when :token_tag_start
          nodes << parse_tag(stream)
        when :token_comment_start
          nodes << parse_comment(stream)
        when :token_eof
          nodes << stream.current
          return RootNode.new(nodes)
        else
          raise "unexpected token: #{token.inspect}"
        end
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_filtered_expression(stream)
      left = parse_primary(stream)
      filters = stream.current.kind == :token_pipe ? parse_filters(stream) : []
      expr = FilteredExpression.new([left, *filters], left, filters)

      if stream.current.kind == :token_if
        parse_ternary_expression(stream, expr)
      else
        expr
      end
    end

    # Parse a _primary_ expression from tokens in _stream_.
    # A primary expression is a literal, a path (to a variable), or a logical
    # expression composed of other primary expressions.
    # @param stream [TokenStream]
    # @return [Node]
    def parse_primary(stream, precedence: Precedence::LOWEST)
      left = case stream.current.kind
             when :token_true
               TrueLiteral.new(stream.next)
             when :token_false
               FalseLiteral.new(stream.next)
             when :token_nil
               NilLiteral.new(stream.next)
             when :token_int
               IntegerLiteral.new(stream.next)
             when :token_float
               FloatLiteral.new(stream.next)
             when :token_single_quote, :token_double_quote
               parse_string_literal(stream)
             when :token_word, :token_lbracket
               parse_path(stream)
             when :token_lparen
               parse_range_lambda_or_grouped_expression(stream)
             when :token_not
               parse_prefix_expression(stream)
             else
               stream.missing("expression")
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
      :token_in,
      :token_and,
      :token_or
    ]

    TERMINATE_OUTPUT = Set[
      :token_whitespace_control,
      :token_output_end,
      :token_other
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
      :token_eof
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

    # @param stream [TokenStream]
    # @return [Node]
    def parse_output(stream)
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
      token = stream.peek # Whitespace control or tag name
      token = stream.peek(2) if token.kind == :token_whitespace_control

      # TODO: handle not a :token_tag_name
      # TODO: handle unknown tag

      @env.tags[token.text].parse(stream, self)
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_comment(stream)
      children = [stream.eat(:token_comment_start), stream.eat_whitespace_control]
      text = stream.eat(:token_comment)
      children << text << stream.eat_whitespace_control << stream.eat(:token_comment_end)
      Comment.new(children, text)
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_string_literal(stream)
      quote_token = stream.next
      term = quote_token.kind # single or double

      children = [quote_token]
      segments = []

      loop do
        case stream.current.kind
        when term
          children << stream.next
          return TemplateString.new(children, segments)
        when :token_string, :token_string_escape
          token = stream.next
          children << token
          segments << StringSegment.new(token)
        when :token_string_interpol
          token = stream.next
          children << token
          node = parse_filtered_expression(stream)
          segments << node
          children << node << stream.eat(:token_string_interpol_end)
        else
          # unclosed string literal
          children << stream.eat(term)
          return TemplateString.new(children, segments)
        end
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_path(stream)
      segments = []

      if stream.current.kind == :token_word
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
        raise "unexpected token in bracketed selector, #{token.kind}"
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
        raise "unexpected token in shorthand selector, #{token.kind}"
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_range_lambda_or_grouped_expression(stream)
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
      if token.kind == :token_comma
        return parse_partial_arrow_function(stream, children,
                                            expr)
      end

      # An arrow function with a single parameter surrounded by parens.
      if token.kind == :token_rparen && stream.peek.kind == :token_arrow
        return parse_partial_arrow_function(stream, children,
                                            expr)
      end

      loop do
        break if TERMINATE_GROUPED_EXPRESSION.member?(token.kind)

        unless BINARY_OPERATORS.member?(token.kind)
          # TODO: or missing
          raise "expected an infix expression, found #{token.kind}"
        end

        expr = parse_infix_expression(stream, expr)
      end

      children << stream.eat(:token_rparen)
      GroupedExpression.new(children, expr)
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_prefix_expression(stream)
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
        raise "unexpected infix operator, #{op_token.text}"
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
      children = [stream.next] # pipe or double pipe
      name = stream.eat(:token_word)
      children << name

      unless stream.current.kind == :token_colon || TERMINATE_FILTER.member?(stream.current.kind) == false
        return Filter.new(children,
                          name,
                          [])
      end

      children << stream.eat(:token_colon)
      args = []

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
      children = []
      params = []

      case stream.current.kind
      when :token_word
        # A single parameter without parens
        token = stream.next
        param = Identifier.new([token], token)
        children << param
        params << param
      when :token_lparen
        # One or move parameters separated by commas and surrounded by parentheses.
        children << stream.next
        while stream.current.kind != :token_rparen
          token = stream.eat(:token_word)
          param = Identifier.new([token], token)
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
      params = []

      # expr should be a single segment path, we need an Identifier.
      param = Identifier.from(expr)
      params << param
      children << param
      children << stream.next if stream.current.kind == :token_comma

      while stream.current.kind != :token_rparen
        token = stream.eat(:token_word)
        param = Identifier.new([token], token)
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
    end
  end
end
