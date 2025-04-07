# frozen_string_literal: true

require_relative "../../node"

module Liquid2
  # The standard _cycle_ tag.
  class CycleTag < Tag
    # @param stream [TokenStream]
    # @param parser [Parser]
    # @return [CycleTag]
    def self.parse(stream, parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      items = [] # : Array[PositionalArgument]
      group_name = nil # : Expression?
      first = parser.parse_primary(stream)

      # Is the first expression followed by a colon? If so, it is a group name
      # followed by items to cycle.
      if stream.current.kind == :token_colon
        group_name = first
        children << group_name << stream.next
      else
        items << PositionalArgument.new([first], first)
      end

      children << stream.next if stream.current.kind == :token_comma

      items.push(*parser.parse_positional_arguments(stream))
      children.push(*items)
      children << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      new(children, group_name, items.map(&:value))
    end

    # @param children [Array<Token | Node>]
    # @param name [Expression?]
    # @param items [Array<Expression>]
    def initialize(children, name, items)
      super(children)
      @name = name
      @items = items
      @blank = false
    end

    def render(context, buffer)
      group_name = (@name || raise).evaluate(context) if @name
      group_name = "" if Liquid2.undefined?(group_name)
      # TODO: explicit nil vs no group name given

      args = @items.map { |expr| expr.evaluate(context) }
      key = group_name || args.to_s
      index = context.cycle(key, args.length)

      return 0 if index >= args.length

      buffer.write(Liquid2.to_output_s(args[index], auto_escape: context.env.auto_escape))
    end
  end
end
