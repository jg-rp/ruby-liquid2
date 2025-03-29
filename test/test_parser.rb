# frozen_string_literal: true

require "test_helper"

# Generate leaf nodes from an AST starting at _node_.
def leaves(node)
  Enumerator.new do |yielder|
    if node.is_a? Liquid2::Token
      yielder << node
    else
      yielder << node if node.children.empty?

      node.children.each do |child|
        leaves(child).each do |item|
          yielder << item
        end
      end
    end
  end
end

class TestParser < Minitest::Spec
  make_my_diffs_pretty!

  TEST_CASES = [
    {
      name: "empty",
      source: ""
    },
    {
      name: "no markup",
      source: "Hello, World!"
    },
    {
      name: "just whitespace",
      source: " \n "
    },
    {
      name: "just output",
      source: "{{ hello }}"
    },
    {
      name: "hello liquid",
      source: "Hello, {{ you }}!"
    },
    {
      name: "dotted path",
      source: "Hello, {{ foo.bar }}!"
    },
    {
      name: "output, empty",
      source: "Hello, {{  }}!"
    },
    {
      name: "output, not closed",
      source: "Hello, {{ foo"
    },
    {
      name: "output, not closed, followed by other",
      source: "Hello, {{ foo <br>"
    },
    {
      name: "output, unexpected, not closed",
      source: "Hello, {{ !"
    },
    {
      name: "output, closed with tag end",
      source: "Hello, {{ foo %}"
    },
    {
      name: "output, literal true",
      source: "Hello, {{ true }}!"
    },
    {
      name: "output, keyword dot path",
      source: "Hello, {{ true.foo }}!"
    },
    {
      name: "output, literal string",
      source: "Hello, {{ 'you' }}!"
    },
    {
      name: "output, template string",
      source: "{{ 'Hello, ${you}!' }}!"
    },
    {
      name: "output, range",
      source: "Hello {{ (1..3) }}!"
    },
    {
      name: "output, filter",
      source: "Hello, {{ you | upcase }}!"
    },
    {
      name: "output, two filters",
      source: "Hello, {{ you | upcase | downcase }}!"
    },
    {
      name: "output, missing filter name",
      source: "Hello, {{ you | }}!"
    },
    {
      name: "output, missing filter name, unknown token",
      source: "Hello, {{ you | * }}!"
    },
    {
      name: "output, filter, positional argument",
      source: "Hello, {{ you | default: 'world' }}!"
    },
    {
      name: "output, filter, positional argument, missing colon",
      source: "Hello, {{ you | default 'world' }}!"
    },
    {
      name: "output, filter, positional and keyword argument",
      source: "Hello, {{ you | default: 'world', allow_false: true }}!"
    },
    {
      name:
        "output, filter, positional and keyword argument, missing comma",
      source: "Hello, {{ you | default: 'world' allow_false: true }}!"
    },
    {
      name: "output, filter, keyword argument, equals",
      source: "Hello, {{ you | default: 'world', allow_false = true }}!"
    },
    {
      name: "output, filter, lambda expression",
      source: "{{ foo | map: i => i.foo.bar }}"
    },
    {
      name: "output, filter, lambda expression with logical and",
      source: "{{ foo | where: i => i.foo and x.bar }}"
    },
    {
      name: "output, filter, lambda expression, two parameters",
      source: "{{ foo | map: (i, j) => i.foo.bar }}"
    },
    {
      name: "output, ternary",
      source: "{{ foo if bar else baz }}"
    },
    {
      name: "output, ternary with logical and",
      source: "{{ foo if bar and x == 42 else baz }}"
    },
    {
      name: "output, ternary with filters",
      source: "{{ foo | upcase if bar else baz || split: ',' }}"
    },
    {
      name: "comment",
      source: "{# some comment #}"
    },
    {
      name: "comment, balanced hashes",
      source: "{## some #} comment ##}"
    },
    {
      name: "comment, output delimiters",
      source: "{# some {{ comment }} #}"
    },
    {
      name: "comment, tag delimiters",
      source: "{# some {% comment %} #}"
    },
    {
      name: "assign",
      source: "{% assign x = y %}"
    }
  ].freeze

  describe "parse template" do
    TEST_CASES.each do |test_case|
      it test_case[:name] do
        template = Liquid2::DEFAULT_ENVIRONMENT.parse(test_case[:source])

        # Serializing a template is equal to source text.
        _(template.to_s).must_equal(test_case[:source])

        leaf_tokens = leaves(template.ast).to_a

        # All leaves are tokens, not nodes.
        _(leaf_tokens.all? { |node| node.is_a?(Liquid2::Token) }).must_equal(true)

        # Concatenating leaf tokens reconstructs the input text
        _(leaf_tokens.map(&:full_text).join).must_equal(test_case[:source])
      end
    end
  end
end
