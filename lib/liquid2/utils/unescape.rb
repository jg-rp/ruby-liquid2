# frozen_string_literal: true

module Liquid2
  # Replace escape sequences with their equivalent Unicode code point.
  # This is a bit like Ruby's String#undump, but assumes surrounding quotes have been removed
  # and follows JSON escaping semantics.
  # @param value [String]
  # @param quote [String] one of '"' or "'".
  # @param token [Token]
  # @return [String] A new string without escape sequences.
  def self.unescape_string(value, quote, token)
    unescaped = String.new(encoding: "UTF-8")
    index = 0
    length = value.length

    while index < length
      ch = value[index] || raise
      if ch == "\\"
        index += 1
        case value[index]
        when quote
          unescaped << quote
        when "\\"
          unescaped << "\\"
        when "/"
          unescaped << "/"
        when "b"
          unescaped << "\x08"
        when "f"
          unescaped << "\x0C"
        when "n"
          unescaped << "\n"
        when "r"
          unescaped << "\r"
        when "t"
          unescaped << "\t"
        when "u"
          code_point, index = Liquid2.decode_hex_char(value, index, token)
          unescaped << Liquid2.code_point_to_string(code_point, token)
        when "$"
          unescaped << "$"
        else
          raise LiquidSyntaxError.new("unknown escape sequence", token)
        end
      else
        # raise LiquidSyntaxError.new("invalid character #{ch.inspect}", token) if ch.ord <= 0x1F

        unescaped << ch
      end

      index += 1

    end

    unescaped
  end

  def self.decode_hex_char(value, index, token)
    length = value.length

    raise LiquidSyntaxError.new("incomplete escape sequence", token) if index + 4 >= length

    index += 1 # move past 'u'
    code_point = parse_hex_digits(value[index, 4] || raise, token)

    raise LiquidSyntaxError.new("unexpected low surrogate", token) if low_surrogate?(code_point)

    return [code_point, index + 3] unless high_surrogate?(code_point)

    unless index + 9 < length && value[index + 4] == "\\" && value[index + 5] == "u"
      raise LiquidSyntaxError.new("incomplete escape sequence", token)
    end

    low_surrogate = parse_hex_digits(value[index + 6, 10] || raise, token)

    unless low_surrogate?(low_surrogate)
      raise LiquidSyntaxError.new("unexpected low surrogate",
                                  token)
    end

    code_point = 0x10000 + (
      ((code_point & 0x03FF) << 10) | (low_surrogate & 0x03FF)
    )

    [code_point, index + 9]
  end

  def self.parse_hex_digits(digits, token)
    code_point = 0
    digits.each_byte do |b|
      code_point <<= 4
      case b
      when 48..57
        code_point |= b - 48
      when 65..70
        code_point |= b - 65 + 10
      when 97..102
        code_point |= b - 97 + 10
      else
        raise LiquidSyntaxError.new("invalid escape sequence", token)
      end
    end
    code_point
  end

  def self.high_surrogate?(code_point)
    code_point.between?(0xD800, 0xDBFF)
  end

  def self.low_surrogate?(code_point)
    code_point.between?(0xDC00, 0xDFFF)
  end

  def self.code_point_to_string(code_point, token)
    raise LiquidSyntaxError.new("invalid character", token) if code_point <= 8

    code_point.chr(Encoding::UTF_8)
  end
end
