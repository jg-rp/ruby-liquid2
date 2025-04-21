# frozen_string_literal: true

require "json"
require "liquid2"

source = <<~LIQUID
  {% for x in (1..4) %}
    {{ greeting }}, {{ customer.first_name }}!
  {% endfor %}
LIQUID

data = JSON.parse <<~DATA
  {
        "customer": {
          "first_name": "Holly"
        },
        "greeting": "Hello"
      }
DATA

scanner = StringScanner.new("")
Liquid2::Scanner.tokenize(source, scanner).each do |token|
  p token
end

env = Liquid2::Environment.new

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
