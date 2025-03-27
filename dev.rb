# frozen_string_literal: true

require "json"
require "liquid2"

source = "{{ foo | map: (i, j) => i.foo.bar }}"

env = Liquid2::Environment.new
template = env.parse(source)

puts JSON.pretty_generate(template.dump)

puts template
