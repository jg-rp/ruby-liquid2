# frozen_string_literal: true

require "json"
require "liquid2"

source = <<~LIQUID
  {# hello #}
  {% if false %}
  {#
  # foo bar
  # foo bar
  #}
  {% endif %}
  {% for x in (1..3) %}
  {% if true %}
  {# goodbye #}
  {% endif %}
  {% endfor %}
  {# world #}
LIQUID

data = JSON.parse <<~DATA
  {
        "a": "foo"
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

t.comments.map(&:text).each do |s|
  puts "> #{s.inspect}"
end

# pp t.ast

# puts t.render(data)

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
