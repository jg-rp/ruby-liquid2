# frozen_string_literal: true

require "liquid2"

source = "{{ 'Hello\\n, world' }}"

tokens = Liquid2.tokenize(source)
tokens.each do |token|
  p token
end
