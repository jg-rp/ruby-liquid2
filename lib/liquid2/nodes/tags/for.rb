# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _for_ tag.
  class ForTag < Tag
    END_BLOCK = Set["endfor", "else"]

    def self.parse(parser)
      token = parser.previous # token_tag_name
      expression = parser.parse_loop_expression
      # TODO: replace these two with `parser.expect_end_of_tag`
      parser.carry_whitespace_control
      parser.eat(:token_tag_end)

      block = parser.parse_block(END_BLOCK)

      if parser.tag?("else")
        parser.eat_empty_tag("else")
        default = parser.parse_block(END_BLOCK)
      else
        default = nil
      end

      parser.eat_empty_tag("endfor")
      new(token, expression, block, default)
    end

    # @param token [[Symbol, String?, Integer]]
    # @param expression [LoopExpression]
    # @param block [Block]
    # @param default [Block?]
    def initialize(token, expression, block, default)
      super(token)
      @expression = expression
      @block = block
      @default = default
      @blank = block.blank && (!default || default.blank)
    end

    def render(context, buffer)
      array = @expression.evaluate(context)

      if array.empty?
        return @default ? (@default || raise).render(context, buffer) : 0
      end

      name = @expression.identifier.name
      forloop = ForLoop.new(@expression.name, array, context.parent_loop(self))
      namespace = { "forloop" => forloop }

      context.loop(namespace, forloop) do
        index = 0
        while (item = array[index])
          namespace[name] = item
          index += 1
          forloop.next
          @block.render(context, buffer)
          case context.interrupts.pop
          when :continue
            next
          when :break
            break
          end
        end
      end
    end
  end

  # The standard _break_ tag.
  class BreakTag < Tag
    def self.parse(parser)
      parser.carry_whitespace_control
      new(parser.eat(:token_tag_end))
    end

    def render(context, _buffer)
      context.interrupts << :break
    end
  end

  # The standard _continue_ tag.
  class ContinueTag < Tag
    def self.parse(parser)
      parser.carry_whitespace_control
      new(parser.eat(:token_tag_end))
    end

    def render(context, _buffer)
      context.interrupts << :continue
    end
  end

  # `for` loop helper variables.
  class ForLoop
    attr_reader :name, :length, :parentloop

    KEYS = Set[
      "name",
      "length",
      "index",
      "index0",
      "rindex",
      "rindex0",
      "first",
      "last",
      "parentloop",
    ]

    def initialize(name, array, parent_loop)
      @name = name
      @array = array
      @length = array.length
      @parentloop = parent_loop
      @index = -1
    end

    def key?(key)
      KEYS.member?(key)
    end

    def fetch(key, default = :undefined)
      if KEYS.member?(key)
        send(key)
      else
        default
      end
    end

    def next = @index += 1
    def index = @index + 1
    def index0 = @index
    def rindex = @length - @index
    def rindex0 = @length - @index - 1
    def first = @index.zero?
    def last = @index == @length - 1
  end
end
