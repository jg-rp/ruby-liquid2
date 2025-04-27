# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _cycle_ tag.
  class CycleTag < Tag
    # @param parser [Parser]
    # @return [CycleTag]
    def self.parse(token, parser)
      items = [] # : Array[untyped]
      group_name = nil # : untyped?
      named = false
      first = parser.parse_primary

      # Is the first expression followed by a colon? If so, it is a group name
      # followed by items to cycle.
      if parser.current_kind == :token_colon
        group_name = first
        named = true
        parser.next
      else
        items << first
      end

      parser.next if parser.current_kind == :token_comma

      items.push(*parser.parse_positional_arguments)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, group_name, items, named)
    end

    # @param name [Expression?]
    # @param items [Array<Expression>]
    def initialize(token, name, items, named)
      super(token)
      @name = name
      @items = items
      @named = named
      @blank = false
    end

    def render(context, buffer)
      args = @items.map { |expr| context.evaluate(expr) }

      key = if @named
              context.evaluate(@name).to_s
            else
              @items.to_s
            end

      index = context.tag_namespace[:cycles][key]
      buffer << Liquid2.to_output_s(args[index])

      index += 1
      index = 0 if index >= @items.length
      context.tag_namespace[:cycles][key] = index
    end

    def expressions = @items
  end
end
