# frozen_string_literal: true

require "json"
require "liquid2"

env = Liquid2::Environment.new
t = env.parse(<<~LIQUID
  START
  {% for x in y -%}
  {% if forloop.index == 3 %}{% continue %}{% endif ~%}
    - {{ x }}
  {% endfor ~%}
  END
LIQUID
             )

# puts JSON.pretty_generate(t.ast.dump)

puts t.render({ "y" => [1, 2, 3, 4, 5] })

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
