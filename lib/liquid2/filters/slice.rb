# frozen_string_literal: true

module Liquid2
  class SliceFilter
    def call(input, start: nil, stop: nil, step: nil)
      input = Liquid2.to_s(input) unless input.is_a?(Array)

      step = Liquid2.to_i(step || 1)
      length = input.length
      return [] if length.zero? || step.zero?

      start = Liquid2.to_i(start) unless start.nil?
      stop = Liquid2.to_i(stop) unless stop.nil?

      normalized_start = if start.nil?
                           step.negative? ? length - 1 : 0
                         elsif start&.negative?
                           [length + start, 0].max
                         else
                           [start, length - 1].min
                         end

      normalized_stop = if stop.nil?
                          step.negative? ? -1 : length
                        elsif stop&.negative?
                          [length + stop, -1].max
                        else
                          [stop, length].min
                        end

      # This does not work with Ruby 3.1
      # input[(normalized_start...normalized_stop).step(step)]
      #
      # But this does.
      (normalized_start...normalized_stop).step(step).map { |i| input[i] }
    end

    def parameters
      method(:call).parameters
    end
  end
end
