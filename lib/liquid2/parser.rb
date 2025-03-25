# frozen_string_literal: true

require_relative "token_stream"
require_relative "builtin/other"

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

      if stream.current.kind == :token_word && stream.current.value == "if"
        parse_ternary_expression(stream, expr)
      else
        expr
      end
    end

    def parse_primary(stream, precedence: Precedence::LOWEST)
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

    # TODO: strings and :symbol or dedicated symbols?
    PRECEDENCES = {
      "and" => Precedence::LOGICAL_AND,
      "or" => Precedence::LOGICAL_OR,
      "not" => Precedence::PREFIX,
      ")" => Precedence::LOWEST,
      "contains" => Precedence::MEMBERSHIP,
      "==" => Precedence::RELATIONAL,
      "<" => Precedence::RELATIONAL,
      ">" => Precedence::RELATIONAL,
      "!=" => Precedence::RELATIONAL,
      "<>" => Precedence::RELATIONAL,
      "<=" => Precedence::RELATIONAL,
      ">=" => Precedence::RELATIONAL
    }.freeze

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
  end
end
