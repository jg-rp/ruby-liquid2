# frozen_string_literal: true

require_relative "../../tag"

module Liquid2
  # The standard _for_ tag.
  class ForTag < Tag
    END_BLOCK = Set["endfor", "else"]

    def self.parse(stream, parser)
      # @type var children: Array[Token | Node]
      children = [stream.eat(:token_tag_start),
                  stream.eat_whitespace_control,
                  stream.eat(:token_tag_name)]

      expression = parser.parse_loop_expression(stream)
      # TODO: skip until ..
      children << expression << stream.eat_whitespace_control << stream.eat(:token_tag_end)
      block = parser.parse_block(stream, END_BLOCK)
      children << block

      if stream.tag?("else")
        children.push(*stream.eat_empty_tag("else"))
        default = parser.parse_block(stream, END_BLOCK)
        children << default
      else
        default = nil
      end

      children.push(*stream.eat_empty_tag("endfor"))
      new(children, expression, block, default)
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
      enum, length = @expression.evaluate(context)

      if length.zero?
        return @default ? (@default || raise).render(context, buffer) : 0
      end

      char_count = 0
      name = @expression.identifier.name

      forloop = ForLoop.new("#{name}-#{@expression.enum.text}",
                            enum,
                            length,
                            context.parent_loop(self))

      namespace = {
        "forloop" => forloop,
        name => nil
      }

      context.loop(namespace, forloop) do
        forloop.each do |item|
          namespace[name] = item
          char_count += @block.render(context, buffer)
          if (interrupt = context.interrupts.pop)
            next if interrupt == :continue
            break if interrupt == :break
          end
        end
      end

      char_count
    end
  end

  # The standard _break_ tag.
  class BreakTag < Tag
    def self.parse(stream, _parser)
      new(stream.eat_empty_tag("break"))
    end

    def render(context, _buffer)
      context.interrupts << :break
      0
    end
  end

  # The standard _continue_ tag.
  class ContinueTag < Tag
    def self.parse(stream, _parser)
      new(stream.eat_empty_tag("continue"))
    end

    def render(context, _buffer)
      context.interrupts << :continue
      0
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

    def initialize(name, enum, length, parent_loop)
      @name = name
      @enum = enum
      @length = length
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

    def each
      @enum.each do |item|
        @index += 1
        yield item
      end
    end

    def index = @index + 1
    def index0 = @index
    def rindex = @length - @index
    def rindex0 = @length - @index - 1
    def first = @index.zero?
    def last = @index == @length - 1
  end
end
