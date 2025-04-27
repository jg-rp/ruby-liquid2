# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _tablerow_ tag.
  class TableRowTag < Tag
    END_BLOCK = Set["endtablerow"]

    def self.parse(token, parser)
      expression = parser.parse_loop_expression
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)
      block = parser.parse_block(END_BLOCK)
      parser.eat_empty_tag("endtablerow")
      new(token, expression, block)
    end

    def initialize(token, expression, block)
      super(token)
      @expression = expression
      @block = block
      @blank = false
    end

    def render(context, buffer)
      array = @expression.evaluate(context)
      name = @expression.identifier.name

      cols = if @expression.cols
               Liquid2.to_liquid_int(context.evaluate(@expression.cols))
             else
               array.length
             end

      drop = TableRow.new(@expression.name, array.length, cols)
      namespace = { "tablerowloop" => drop }

      buffer << "<tr class=\"row1\">\n"

      context.extend(namespace) do
        index = 0
        while (item = array[index])
          namespace[name] = item
          index += 1
          drop.next

          buffer << "<td class=\"col#{drop.col}\">"
          @block.render(context, buffer)
          buffer << "</td>"

          buffer << "</tr>\n<tr class=\"row#{drop.row + 1}\">" if drop.col_last && !drop.last

          case context.interrupts.pop
          when :continue
            next
          when :break
            break
          end
        end

        buffer << "</tr>\n"
      end
    end

    def children(_static_context, include_partials: true) = [@block]
    def expressions = [@expression]

    def block_scope
      [@expression.identifier,
       Identifier.new([:token_word, "tablerowloop", @expression.token.last])]
    end
  end

  # `tablerow` loop helper variables.
  class TableRow
    attr_reader :name, :length, :col, :row

    KEYS = Set[
      "name",
      "length",
      "index",
      "index0",
      "rindex",
      "rindex0",
      "first",
      "last",
      "col",
      "col0",
      "col_first",
      "col_last",
      "row"
    ]

    def initialize(name, length, cols)
      @name = name
      @length = length
      @cols = cols
      @index = -1
      @row = 1
      @col = 0
    end

    def key?(key)
      KEYS.member?(key)
    end

    def [](key)
      send(key) if KEYS.member?(key)
    end

    def fetch(key, default = :undefined)
      if KEYS.member?(key)
        send(key)
      else
        default
      end
    end

    def next
      @index += 1

      if @col == @cols
        @col = 1
        @row += 1
      else
        @col += 1
      end
    end

    def index = @index + 1
    def index0 = @index
    def rindex = @length - @index
    def rindex0 = @length - @index - 1
    def first = @index.zero?
    def last = @index == @length - 1
    def col0 = @col - 1
    def col_first = @col == 1
    def col_last = @col == @cols
  end
end
