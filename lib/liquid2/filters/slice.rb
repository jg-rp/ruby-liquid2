# frozen_string_literal: true

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return the subsequence of _left_ starting at _start_ up to _length_.
    def self.slice(left, start, length = 1)
      length = 1 if Liquid2.undefined?(length)
      case left
      when Array
        left.slice(to_integer(start), to_integer(length)) || []
      else
        Liquid2.to_s(left).slice(to_integer(start), to_integer(length)) || ""
      end
    end

    def self.better_slice(
      left,
      start_ = :undefined, stop_ = :undefined, step_ = :undefined,
      start: :undefined, stop: :undefined, step: :undefined
    )
      # Give priority to keyword arguments, default to nil if neither are given.
      start = start_ == :undefined ? nil : start_ if start == :undefined
      stop = stop_ == :undefined ? nil : stop_ if stop == :undefined
      step = step_ == :undefined ? nil : step_ if step == :undefined

      step = Integer(step || 1)
      length = left.length
      return [] if length.zero? || step.zero?

      start = Integer(start) unless start.nil?
      stop = Integer(stop) unless stop.nil?

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
      # left[(normalized_start...normalized_stop).step(step)]
      #
      # But this does.
      (normalized_start...normalized_stop).step(step).map { |i| left[i] }
    end
  end
end
