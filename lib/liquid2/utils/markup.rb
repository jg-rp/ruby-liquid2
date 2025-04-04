# frozen_string_literal: true

# MarkupSafe (https://github.com/pallets/markupsafe) inspired escaping and String subclass
# for marking strings as "safe" to using in HTML and XML.
#
# Here's the license for the Python package on which this class is based.
#
# Copyright 2010 Pallets
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# 3.  Neither the name of the copyright holder nor the names of its
#     contributors may be used to endorse or promote products derived from
#     this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "cgi"
require "english"

module Liquid2
  # A string that is safe to be inserted into HTML or XML, either because it is already
  # escaped or because it was explicitly marked as safe.
  #
  # TODO: finish me
  # TODO: test me
  #
  class Markup < String
    RE_ESCAPE = Regexp.new("[&><'\"]")

    ESCAPE_MAP = {
      "&" => "&amp;",
      ">" => "&gt;",
      "<" => "&lt;",
      "'" => "&39;",
      '"' => "&34;"
    }.freeze

    def self.escape(object)
      return object if object.is_a?(Markup)

      return new(object.gsub(RE_ESCAPE, ESCAPE_MAP), encoding: "UTF-8") if object.is_a?(String)

      return new(object.to_html, encoding: "UTF-8") if object.respond_to?(:to_html)

      new(object.to_s.gsub(RE_ESCAPE, ESCAPE_MAP), encoding: "UTF-8")
    end

    def self.soft_to_s(object)
      object.is_a?(String) ? object : object.to_s
    end

    def self.try_convert(object)
      new(super(object.respond_to?(:to_html) ? object.to_html : object), encoding: "UTF-8")
    end

    def self.join(array, separator = $OUTPUT_FIELD_SEPARATOR) # steep:ignore UnknownGlobalVariable
      new(array.map { |item| escape(item) }.join(separator))
    end

    def to_html
      self
    end

    def inspect
      "#{self.class}(#{super})"
    end

    def %(_other)
      raise "not implemented"
    end

    def *(other)
      self.class.new(super)
    end

    def +(other)
      self.class.new(super(self.class.escape(other)))
    end

    def -(_other)
      raise "not implemented"
    end

    def [](...)
      self.class.new(super) # steep:ignore
    end

    def slice(...)
      self.class.new(super) # steep:ignore
    end

    def []=(...)
      raise "not implemented"
    end

    def split(field_sep = $FIELD_SEPARATOR, limit = 0) # steep:ignore UnknownGlobalVariable
      super { |string| self.class.new(string) }
    end

    def capitalize(...)
      self.class.new(super)
    end

    def downcase(...)
      self.class.new(super)
    end

    def each_line(...)
      super { |substring| self.class.new(substring) }
    end

    def gsub(...)
      raise "TODO"
    end

    def gsub!(...)
      raise "TODO"
    end

    def insert(index, other_string)
      super(index, self.class.escape(other_string))
    end

    def lines(...)
      super { |substring| self.class.new(substring) }
    end

    def prepend(*other_strings)
      super(*other_strings.map { |string| self.class.escape(string) })
    end

    def sub(...)
      raise "TODO"
    end

    def sub!(...)
      raise "TODO"
    end

    def strip
      self.class.new(super)
    end

    def lstrip
      self.class.new(super)
    end

    def rstrip
      self.class.new(super)
    end

    def ljust(size, pad_string = "")
      self.class.new(super(size, self.class.escape(pad_string)))
    end

    def rjust(size, pad_string = "")
      self.class.new(super(size, self.class.escape(pad_string)))
    end

    def center(size, pad_string = "")
      self.class.new(super(size, self.class.escape(pad_string)))
    end

    def partition(string_or_regexp)
      super.map { |substring| self.class.new(substring) }
    end

    def rpartition(string_or_regexp)
      super.map { |substring| self.class.new(substring) }
    end

    def reverse
      self.class.new(super)
    end

    def unescape
      CGI.unescapeHTML(self)
    end

    def upcase(...)
      self.class.new(super)
    end
  end
end
