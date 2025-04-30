# frozen_string_literal: true

require "json"
require "liquid2"

source = <<~LIQUID
  Hello, {{ you }}!
  {% assign x = 'foo' | upcase %}
  {% for ch in x %}
      - {{ ch }}
  {% endfor %}
  Goodbye, {{ you.first_name | capitalize }} {{ you.last_name }}
  Goodbye, {{ you.first_name }} {{ you.last_name }}
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

class MockLoader < Liquid2::HashLoader
  def initialize(templates, matter)
    super(templates)
    @matter = matter
  end

  def get_source(env, name, context: nil, **kwargs)
    source = super
    Liquid2::TemplateSource.new(source: source.source, name: source.name, matter: @matter[name])
  end
end

loader = MockLoader.new(
  {
    "some" => "Hello, {{ you }}{{ username }}!",
    "other" => "Goodbye, {{ you }}{{ username }}.",
    "thing" => "{{ you }}{{ username }}"
  },
  {
    "some" => { "you" => "World" },
    "other" => { "username" => "Smith" }
  }
)

env = Liquid2::Environment.new(loader: loader)
template = env.get_template("some")

p template.render

# scanner = StringScanner.new("")
# Liquid2::Scanner.tokenize(source, scanner).each do |token|
#   p token
# end

# env = Liquid2::Environment.new(loader: loader)

# t = env.parse(source)

# t.comments.map(&:text).each do |s|
#   puts "> #{s.inspect}"
# end

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
