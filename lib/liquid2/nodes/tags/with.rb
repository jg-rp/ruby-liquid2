# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The _with_ tag.
  class WithTag < Tag
    END_BLOCK = Set["endwith"]

    # @param token [[Symbol, String?, Integer]]
    # @param parser [Parser]
    # @return [WithTag]
    def self.parse(token, parser)
      parser.next if parser.current_kind == :token_comma
      args = parser.parse_keyword_arguments
      parser.next if parser.current_kind == :token_comma
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      block = parser.parse_block(END_BLOCK)
      parser.eat_empty_tag("endwith")
      new(token, args, block)
    end

    # @param token [[Symbol, String?, Integer]]
    # @param args [Array[KeywordArgument]]
    # @param block [Block]
    def initialize(token, args, block)
      super(token)
      @args = args
      @block = block
      @blank = block.blank
    end

    def render(context, buffer)
      namespace = @args.to_h { |arg| [arg.name, context.evaluate(arg.value)] }
      context.extend(namespace) do
        @block.render(context, buffer)
      end
    end

    def children(_static_context, include_partials: true) = [@block]
    def block_scope = @args.map { |arg| Identifier.new(arg.token) }
  end
end
