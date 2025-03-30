# frozen_string_literal: true

require "json"
require "liquid2"

env = Liquid2::Environment.new
t = env.parse(<<~LIQUID
  {% assign you = 'World' %}
  {% assign x = 'Hello, ${you}!' %}
  {{ x }}
LIQUID
             )

# puts JSON.pretty_generate(t.ast.dump)

puts t.render

# TODO: whitespace control
# TODO: parse block

# TODO: document the drop interface
#   - #to_liquid(context)
#   - #fetch(key, default = :undefined)  with optional context
#   - #key? : (String) -> bool

# TODO: document the filter interface
#   - #call(left, *args, context:, **kwargs)
#   - #parameters
