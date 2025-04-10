# frozen_string_literal: true

require "cgi"

module Liquid2
  # Liquid filters and helper methods.
  module Filters
    # Return _left_ concatenated with _right_.
    # Coerce _left_ and _right_ to strings if they aren't strings already.
    def self.append(left, right)
      Liquid2.to_s(left) + Liquid2.to_s(right)
    end

    # Return _left_ with the first character in uppercase and the rest lowercase.
    # Coerce _left_ to a string if it is not one already.
    def self.capitalize(left)
      Liquid2.to_s(left).capitalize
    end

    # Return _left_ with all characters converted to lowercase.
    # Coerce _left_ to a string if it is not one already.
    def self.downcase(left)
      Liquid2.to_s(left).downcase
    end

    # Return _left_ with special HTML characters replaced with their HTML-safe escape sequences.
    # Coerce _left_ to a string if it is not one already.
    def self.escape(left)
      CGI.escape_html(Liquid2.to_s(left)) unless left.nil?
    end

    # Return _left_ with special HTML characters replaced with their HTML-safe escape sequences.
    # Coerce _left_ to a string if it is not one already.
    #
    # It is safe to use `escape_once` on string values that already contain HTML-escape sequences.
    def self.escape_once(left)
      CGI.escape_html(CGI.unescape_html(Liquid2.to_s(left)))
    end

    # Return _left_ with leading whitespace removed.
    # Coerce _left_ to a string if it is not one already.
    def self.lstrip(left)
      Liquid2.to_s(left).lstrip
    end

    # Return _left_ with trailing whitespace removed.
    # Coerce _left_ to a string if it is not one already.
    def self.rstrip(left)
      Liquid2.to_s(left).rstrip
    end

    # Return _left_ with LF or CRLF replaced with `<br />\n`.
    def self.newline_to_br(left)
      Liquid2.to_s(left).gsub(/\r?\n/, "<br />\n")
    end

    # Return _right_ concatenated with _left_.
    # Coerce _left_ and _right_ to strings if they aren't strings already.
    def self.prepend(left, right)
      Liquid2.to_s(right) + Liquid2.to_s(left)
    end

    # Return _left_ with all occurrences of _pattern_ replaced with _replacement_.
    # All arguments are coerced to strings if they aren't strings already.
    def self.replace(left, pattern, replacement = "")
      Liquid2.to_s(left).gsub(Liquid2.to_s(pattern), Liquid2.to_s(replacement))
    end

    # Return _left_ with the first occurrence of _pattern_ replaced with _replacement_.
    # All arguments are coerced to strings if they aren't strings already.
    def self.replace_first(left, pattern, replacement = "")
      Liquid2.to_s(left).sub(Liquid2.to_s(pattern), Liquid2.to_s(replacement))
    end

    # Return _left_ with the last occurrence of _pattern_ replaced with _replacement_.
    # All arguments are coerced to strings if they aren't strings already.
    def self.replace_last(left, pattern, replacement)
      return left + replacement if Liquid2.undefined?(pattern)

      head, match, tail = Liquid2.to_s(left).rpartition(Liquid2.to_s(pattern))
      return left if match.empty?

      head + Liquid2.to_s(replacement) + tail
    end

    # Return _left_ with all occurrences of _pattern_ removed.
    # All arguments are coerced to strings if they aren't strings already.
    def self.remove(left, pattern)
      Liquid2.to_s(left).gsub(Liquid2.to_s(pattern), Liquid2.to_s(""))
    end

    # Return _left_ with the first occurrence of _pattern_ removed.
    # All arguments are coerced to strings if they aren't strings already.
    def self.remove_first(left, pattern)
      Liquid2.to_s(left).sub(Liquid2.to_s(pattern), Liquid2.to_s(""))
    end

    # Return _left_ with the last occurrence of _pattern_ removed.
    # All arguments are coerced to strings if they aren't strings already.
    def self.remove_last(left, pattern)
      return left if Liquid2.undefined?(pattern)

      head, match, tail = Liquid2.to_s(left).rpartition(Liquid2.to_s(pattern))
      return left if match.empty?

      head + tail
    end
  end
end
