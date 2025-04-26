# frozen_string_literal: true

require "json"
require "liquid2"

source = <<~LIQUID
  {% assign x = y | append: z %}
LIQUID

data = JSON.parse <<~DATA
  {"you": "World", "something": " and Liquid"}
DATA

templates = JSON.parse <<~TEMPLATES
  {
        "a": "{{ a }}{% break %}"
      }
TEMPLATES

# loader = Liquid2::HashLoader.new(templates)

loader = Liquid2::CachingFileSystemLoader.new("test/cts/benchmark_fixtures/001/templates/")

# scanner = StringScanner.new("")
# Liquid2::Scanner.tokenize(source, scanner).each do |token|
#   p token
# end

env = Liquid2::Environment.new(loader: loader)

# t = env.parse(source)

t = env.get_template("index.liquid")
u = env.get_template("index.liquid")

# pp t.ast

# # puts JSON.pretty_generate(t.ast.dump)

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
