# frozen_string_literal: true

require "set"
require_relative "token_stream"
require_relative "nodes/other"
require_relative "nodes/expressions/literals"
require_relative "nodes/expressions/string"

module Liquid2
  class Parser
    # @param env [Environment]
    def initialize(env)
      @env = env
    end

    # Parse Liquid template text into an AST.
    # @param source [String]
    # @return [Array<Node>]
    def parse(source)
      nodes = []
      stream = TokenStream.new(source)

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
          return nodes
        else
          raise "unexpected token: #{token.inspect}"
        end
      end
    end

    # @param stream [TokenStream]
    # @return [Node]
    def parse_filtered_expression(stream)
      left = parse_primary(stream)
      filters = parse_filters(stream)
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
               stream.peek(2).kind == :token_double_dot ? parse_range(stream) : missing(stream)
             when :token_not
               parse_prefix_expression(stream)
             else
               # TODO: or missing
               raise "expected primitive expression, found #{token.kind}"
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

    # @param stream [TokenStream]
    # @return [Node]
    def parse_output(stream)
      children = [stream.eat(:token_output_start), stream.eat_whitespace_control]
      expr = parse_filtered_expression(stream)
      # TODO: skip until terminate output
      children << expr << stream.eat_whitespace_control << stream.eat(:token_output_end)
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
  end
end
