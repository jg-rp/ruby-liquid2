# frozen_string_literal: true

require "liquid2"

source = "Hello, {{ you | upcase }}!"

env = Liquid2::Environment.new
parser = Liquid2::Parser.new(env)
root = parser.parse(source)

pp root.dump

puts root
