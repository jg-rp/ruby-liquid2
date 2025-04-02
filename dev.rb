# frozen_string_literal: true

require "json"
require "liquid2"

env = Liquid2::Environment.new
source = <<~LIQUID
  START
  {% liquid
    assign username = "Brian"

    if username
      echo "Hello, " | append: username
    else
      echo "Hello, user"
    endif

    for i in (1..3)
      echo i
    endfor -%}
  END
LIQUID

# Liquid2.tokenize(source).each do |token|
#   puts "#{token.kind.to_s.ljust(50)} -> #{token.text.inspect}"
# end

t = env.parse(source)

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
