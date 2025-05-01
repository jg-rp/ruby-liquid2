# frozen_string_literal: true

require "json"
require "liquid2"

source = <<~LIQUID
  {% liquid
    for item in a, b, '42', false
        echo "- ${item}\n"
    endfor %}
LIQUID

data = JSON.parse <<~DATA
  {
        "a": "Hello",
        "b": "World"
      }
DATA

templates = JSON.parse <<~TEMPLATES
  {
        "a": "{{ a }}{% break %}"
      }
TEMPLATES

# env = Liquid2::Environment.new
# template = env.parse(source)

# p template.render

# scanner = StringScanner.new("")
# Liquid2::Scanner.tokenize(source, scanner).each do |token|
#   p token
# end

env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(templates))

t = env.parse(source)

# pp t.ast

puts t.render(data)

# analysis = Liquid2::StaticAnalysis.analyze(t, include_partials: false)

# pp analysis

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
