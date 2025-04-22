# frozen_string_literal: true

require "json"
require "liquid2"

source = <<~LIQUID
  {% assign count = 0 -%}

  {% for name in names -%}
    {% assign count = count | plus: 1 -%}
    {% assign upper_name = name | upcase -%}
    {% assign greeting = "Hello, " | append: upper_name | append: "!" -%}
    {% assign remainder = count | modulo: 2 -%}

    {% if remainder == 0 -%}
      {% assign greeting = greeting | append: " You're even-numbered." -%}
    {% else -%}
      {% assign greeting = greeting | append: " You're odd-numbered." -%}
    {% endif -%}

    {{ greeting }}
  {% endfor %}
LIQUID

data = JSON.parse <<~DATA
    {
    "names": [
      "Alice",
      "Bob",
      "Charlie",
      "David",
      "Eva",
      "Frank",
      "Grace",
      "Hank",
      "Ivy",
      "Jack"
    ]
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
