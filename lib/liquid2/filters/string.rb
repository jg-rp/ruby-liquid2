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

    # Return _left_ with all characters converted to uppercase.
    # Coerce _left_ to a string if it is not one already.
    def self.upcase(left)
      Liquid2.to_s(left).upcase
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

    # Return _left_ with leading and trailing whitespace removed.
    # Coerce _left_ to a string if it is not one already.
    def self.strip(left)
      Liquid2.to_s(left).strip
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

    # Split _left_ on every occurrence of _pattern_.
    def self.split(left, pattern)
      Liquid2.to_s(left).split(Liquid2.to_s(pattern))
    end

    RE_HTML_BLOCKS = Regexp.union(
      %r{<script.*?</script>}m,
      /<!--.*?-->/m,
      %r{<style.*?</style>}m
    )

    RE_HTML_TAGS = /<.*?>/m

    # Return _left_ with HTML tags removed.
    def self.strip_html(left)
      Liquid2.to_s(left).gsub(RE_HTML_BLOCKS, "").gsub(RE_HTML_TAGS, "")
    end

    # Return _left_ with CR and LF removed.
    def self.strip_newlines(left)
      Liquid2.to_s(left).gsub(/\r?\n/, "")
    end

    def self.truncate(left, max_length = 50, ellipsis = "...")
      return if left.nil? || Liquid2.undefined?(left)

      left = Liquid2.to_s(left)
      max_length = to_integer(max_length)
      return left if left.length <= max_length

      ellipsis = Liquid2.to_s(ellipsis)
      return ellipsis[0, max_length] if ellipsis.length >= max_length

      "#{left[0...max_length - ellipsis.length]}#{ellipsis}"
    end

    def self.truncatewords(left, max_words = 15, ellipsis = "...")
      return if left.nil? || Liquid2.undefined?(left)

      left = Liquid2.to_s(left)
      max_words = to_integer(max_words).clamp(1, 10_000)
      words = left.split(" ", max_words + 1)
      return left if words.length <= max_words

      ellipsis = Liquid2.to_s(ellipsis)
      words.pop
      "#{words.join(" ")}#{ellipsis}"
    end

    def self.url_encode(left)
      CGI.escape(Liquid2.to_s(left)) unless left.nil? || Liquid2.undefined?(left)
    end

    def self.url_decode(left)
      return if left.nil? || Liquid2.undefined?(left)

      decoded = CGI.unescape(Liquid2.to_s(left))
      unless decoded.valid_encoding?
        raise Liquid2::LiquidArgumentError.new("invalid byte sequence", nil)
      end

      decoded
    end
  end
end
