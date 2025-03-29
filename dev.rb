# frozen_string_literal: true

require "json"
require "liquid2"

env = Liquid2::Environment.new
t = env.parse("Hello, {{ 'foo' | upcase }}!")

# puts JSON.pretty_generate(t.ast.dump)

puts t.render

# TODO: document the drop interface
#   - #to_liquid(context)
#   - #fetch(key, default = :undefined)  with optional context

# TODO: document the filter interface
#   - #call(left, *args, context:, **kwargs)
