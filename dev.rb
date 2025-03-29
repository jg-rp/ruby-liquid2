# frozen_string_literal: true

require "json"
require "liquid2"

env = Liquid2::Environment.new
t = env.parse("Hello, {{ you }}!")
ctx = Liquid2::RenderContext.new(t)
ctx.assign("foo", 42)

p ctx.resolve("foo")

# puts JSON.pretty_generate(t.ast.dump)

# TODO: document the drop interface
#   - #to_liquid(context)
#   - #fetch(key, default = :undefined)  with optional context

# TODO: document the filter interface
#   - #call(left, *args, context:, **kwargs)
