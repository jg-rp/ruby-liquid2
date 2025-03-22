# frozen_string_literal: true

require "liquid2"

lexer = Liquid2::Lexer.new("Hello, {# {{ you }}! {% assign x = y %} #}")
lexer.debug
