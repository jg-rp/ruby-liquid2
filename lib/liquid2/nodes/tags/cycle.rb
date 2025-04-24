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
      first = parser.parse_primary

      # Is the first expression followed by a colon? If so, it is a group name
      # followed by items to cycle.
      if parser.current_kind == :token_colon
        raise LiquidSyntaxError.new("expected an identifier", token) unless first.is_a?(Path)

        unless first.segments.empty?
          raise LiquidSyntaxError.new("expected an identifier, found a path",
                                      token)
        end

        group_name = first.head
        parser.next
      else
        items << first
      end

      parser.next if parser.current_kind == :token_comma

      items.push(*parser.parse_positional_arguments)
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      new(token, group_name, items)
    end

    # @param name [Expression?]
    # @param items [Array<Expression>]
    def initialize(token, name, items)
      super(token)
      @name = name
      @items = items
      @blank = false
    end

    def render(context, buffer)
      group_name = context.evaluate(@name || raise) if @name
      group_name = "" if Liquid2.undefined?(group_name)
      # TODO: explicit nil vs no group name given

      args = @items.map { |expr| context.evaluate(expr) }
      key = "#{group_name}-#{args}"
      index = context.cycle(key, args.length)

      return if index >= args.length

      buffer << Liquid2.to_output_s(args[index])
    end
  end
end
