# frozen_string_literal: true

require "liquid2"

tokens = Liquid2.tokenize("{% assign x = true %}{{ 'Hello ${you}!' }}")
tokens.each do |token|
  p token
end
