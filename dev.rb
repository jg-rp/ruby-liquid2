# frozen_string_literal: true

require "json"
require "liquid2"

templates = {
  "foo" => "Hello, {{ you }}!"
}

env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(templates))
source = <<~LIQUID
  START
  {% include 'foo' %}
  END
LIQUID

# Liquid2.tokenize(source).each do |token|
#   puts "#{token.kind.to_s.ljust(50)} -> #{token.text.inspect}"
# end

t = env.parse(source)

# puts JSON.pretty_generate(t.ast.dump)

puts t.render({ "you" => "World" })

# TODO: document the drop interface
#   - #to_liquid(context)
#   - #fetch(key, default = :undefined)  with optional context
#   - #key? : (String) -> bool
#
# For looping
#   - #slice(Range)
#
# or
#   - #each and
#   - #size

# TODO: document the filter interface
#   - #call(left, *args, context:, **kwargs)
#   - #parameters
