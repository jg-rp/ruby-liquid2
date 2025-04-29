# frozen_string_literal: true

module Liquid2
  # The base class for all Liquid errors.
  class LiquidError < StandardError
    attr_accessor :token, :template_name, :source

    FULL_MESSAGE = ((RUBY_VERSION.split(".")&.map(&:to_i) <=> [3, 2, 0]) || -1) < 1

    def initialize(message, token = nil)
      super(message)
      @token = token
      @template_name = nil
      @source = nil
    end

    def detailed_message(highlight: true, **kwargs)
      return super unless @source.is_a?(String) && @token

      _kind, value, index = @token || raise
      line, col, current_line = error_context(@source || raise, index)

      name_and_position = if @template_name
                            "#{@template_name}:#{line}:#{col}"
                          else
                            "#{current_line.inspect}:#{line}:#{col}"
                          end

      pad = " " * line.to_s.length
      pointer = (" " * col) + ("^" * (value&.length || 1))

      <<~MESSAGE.strip
        #{self.class}: #{message}
        #{pad} -> #{name_and_position}
        #{pad} |
        #{line} | #{current_line}
        #{pad} | #{pointer} #{highlight ? "\e[1m#{message}\e[0m" : message}
      MESSAGE
    end

    def full_message(highlight: true, order: :top)
      if FULL_MESSAGE
        # For Ruby < 3.2.0
        "#{super}\n#{detailed_message(highlight: highlight, order: order)}"
      else
        super
      end
    end

    protected

    def error_context(source, index)
      lines = source.lines
      cumulative_length = 0
      target_line_index = -1

      lines.each_with_index do |line, i|
        cumulative_length += line.length
        next unless index < cumulative_length

        target_line_index = i
        line_number = target_line_index + 1
        column_number = index - (cumulative_length - lines[target_line_index].length)
        return [line_number, column_number, lines[target_line_index].rstrip]
      end

      raise "index is out of bounds for span"
    end
  end

  class LiquidSyntaxError < LiquidError; end
  class LiquidArgumentError < LiquidError; end
  class LiquidTypeError < LiquidError; end
  class LiquidTemplateNotFoundError < LiquidError; end
  class LiquidFilterNotFoundError < LiquidError; end
  class LiquidResourceLimitError < LiquidError; end
  class UndefinedError < LiquidError; end
  class DisabledTagError < LiquidError; end
end
