# frozen_string_literal: true

require "json"
require "liquid2"

source = <<~LIQUID
  Hello, {# this is a comment #} World!
LIQUID

data = JSON.parse <<~DATA
  {
        "a": [
          {
            "x": 99
          },
          {
            "z": 42
          }
        ]
      }
DATA

templates = JSON.parse <<~TEMPLATES
  {
        "a": "{{ a }}{% break %}"
      }
TEMPLATES

loader = Liquid2::HashLoader.new(templates)

scanner = StringScanner.new("")
Liquid2::Scanner.tokenize(source, scanner).each do |token|
  p token
end

env = Liquid2::Environment.new(loader: loader)

t = env.parse(source)

pp t.ast

# # puts JSON.pretty_generate(t.ast.dump)

puts t.render(data)

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
