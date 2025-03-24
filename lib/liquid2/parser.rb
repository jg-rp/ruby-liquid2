# frozen_string_literal: true

require_relative "token_stream"
require_relative "builtin/other"

module Liquid2
  class Parser
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
          # TODO: a tag is anything that responds to `parse(stream, parser)` and returns a Node
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
    def parse_output(stream)
      children = [stream.eat(:token_output_start), stream.eat_whitespace_control]
      expr = parse_filtered_expression(stream)
      # TODO: skip until terminate output
      children << expr << stream.eat_whitespace_control << stream.eat(:token_output_end)
      Output.new(children, expr)
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
  end
end
