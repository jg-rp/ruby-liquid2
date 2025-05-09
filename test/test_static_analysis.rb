# frozen_string_literal: true

require "test_helper"

Span = Liquid2::StaticAnalysis::Span
Var = Liquid2::StaticAnalysis::Variable

class TestStaticAnalysis < Minitest::Test
  make_my_diffs_pretty!

  def assert_analysis(template, locals:, globals:, variables: nil, filters: nil, tags: nil)
    variables ||= globals
    result = template.analyze

    assert_equal(locals, result.locals)
    assert_equal(globals, result.globals)
    assert_equal(variables, result.variables)

    if filters
      assert_equal(filters, result.filters)
    else
      assert_equal(0, result.filters.length)
    end

    if tags
      assert_equal(tags, result.tags)
    else
      assert_equal(0, result.tags.length)
    end
  end

  def test_analyze_output
    source = "{{ x | default: y, allow_false: z }}"

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: {
        "x" => [Var.new(["x"], Span.new("", 3))],
        "y" => [Var.new(["y"], Span.new("", 16))],
        "z" => [Var.new(["z"], Span.new("", 32))]
      },
      filters: { "default" => [Span.new("", 7)] }
    )
  end

  def test_analyze_output_two_xs
    source = "{{ x | default: y, allow_false: z }}{{ x.a }}"

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: {
        "x" => [
          Var.new(["x"], Span.new("", 3)),
          Var.new(%w[x a], Span.new("", 39))
        ],
        "y" => [Var.new(["y"], Span.new("", 16))],
        "z" => [Var.new(["z"], Span.new("", 32))]
      },
      filters: { "default" => [Span.new("", 7)] }
    )
  end

  def test_bracketed_query_notation
    source = "{{ x['y'].title }}"

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: { "x" => [Var.new(%w[x y title], Span.new("", 3))] }
    )
  end

  def test_quoted_name_notation
    source = "{{ some['foo.bar'] }}"

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: { "some" => [Var.new(["some", "foo.bar"], Span.new("", 3))] }
    )
  end

  def test_nested_queries
    source = "{{ x[y.z].title }}"

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: {
        "x" => [Var.new(["x", %w[y z], "title"], Span.new("", 3))],
        "y" => [Var.new(%w[y z], Span.new("", 5))]
      }
    )
  end

  def test_nested_root_query
    source = "{{ [a.b] }}"

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: {
        "[\"a\", \"b\"]" => [Var.new([%w[a b]], Span.new("", 3))],
        "a" => [Var.new(%w[a b], Span.new("", 4))]
      }
    )
  end

  def test_ternary
    source = "{{ a if b.c else d }}"

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: {
        "a" => [Var.new(["a"], Span.new("", 3))],
        "b" => [Var.new(%w[b c], Span.new("", 8))],
        "d" => [Var.new(["d"], Span.new("", 17))]
      }
    )
  end

  def test_ternary_filters
    source = "{{ a | upcase if b.c else d | default: 'x' || append: y }}"

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: {
        "a" => [Var.new(["a"], Span.new("", 3))],
        "b" => [Var.new(%w[b c], Span.new("", 17))],
        "d" => [Var.new(["d"], Span.new("", 26))],
        "y" => [Var.new(["y"], Span.new("", 54))]
      },
      filters: {
        "upcase" => [Span.new("", 7)],
        "default" => [Span.new("", 30)],
        "append" => [Span.new("", 46)]
      }
    )
  end

  def test_assign
    source = "{% assign x = y | append: z %}"

    assert_analysis(
      Liquid2.parse(source),
      locals: { "x" => [Var.new(["x"], Span.new("", 10))] },
      globals: {
        "y" => [Var.new(["y"], Span.new("", 14))],
        "z" => [Var.new(["z"], Span.new("", 26))]
      },
      filters: { "append" => [Span.new("", 18)] },
      tags: { "assign" => [Span.new("", 3)] }
    )
  end

  def test_capture
    source = "{% capture x %}{% if y %}z{% endif %}{% endcapture %}"

    assert_analysis(
      Liquid2.parse(source),
      locals: { "x" => [Var.new(["x"], Span.new("", 11))] },
      globals: {
        "y" => [Var.new(["y"], Span.new("", 21))]
      },
      tags: {
        "capture" => [Span.new("", 3)],
        "if" => [Span.new("", 18)]
      }
    )
  end

  def test_case
    source = <<~LIQUID
      {% case x %}
      {% when y %}
        {{ a }}
      {% when z %}
        {{ b }}
      {% else %}
        {{ c }}
      {% endcase %}
    LIQUID

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: {
        "x" => [Var.new(["x"], Span.new("", 8))],
        "y" => [Var.new(["y"], Span.new("", 21))],
        "a" => [Var.new(["a"], Span.new("", 31))],
        "z" => [Var.new(["z"], Span.new("", 44))],
        "b" => [Var.new(["b"], Span.new("", 54))],
        "c" => [Var.new(["c"], Span.new("", 75))]
      },
      tags: { "case" => [Span.new("", 3)] }
    )
  end

  def test_macro_and_call
    source = <<~LIQUID
      {% macro 'foo', you: 'World', arg: n %}
      Hello, {{ you }}!
      {% endmacro %}
      {% call 'foo' %}
      {% assign x = 'you' %}
      {% call 'foo', you: x %}
    LIQUID

    assert_analysis(
      Liquid2.parse(source),
      locals: { "x" => [Var.new(["x"], Span.new("", 100))] },
      globals: {
        "n" => [Var.new(["n"], Span.new("", 35))]
      },
      variables: {
        "n" => [Var.new(["n"], Span.new("", 35))],
        "you" => [Var.new(["you"], Span.new("", 50))],
        "x" => [Var.new(["x"], Span.new("", 133))]
      },
      tags: {
        "macro" => [Span.new("", 3)],
        "call" => [Span.new("", 76), Span.new("", 116)],
        "assign" => [Span.new("", 93)]
      }
    )
  end

  def test_with
    source = <<~LIQUID.chomp
      {% with a: 1, b: 3.4 -%}
      {{ a }} + {{ b }} = {{ a | plus: b }}
      {%- endwith -%}
      {{ a }}
    LIQUID

    assert_analysis(
      Liquid2.parse(source),
      locals: {},
      globals: { "a" => [Var.new(["a"], Span.new("", 82))] },
      variables: {
        "a" => [
          Var.new(["a"], Span.new("", 28)),
          Var.new(["a"], Span.new("", 48)),
          Var.new(["a"], Span.new("", 82))
        ],
        "b" => [
          Var.new(["b"], Span.new("", 38)),
          Var.new(["b"], Span.new("", 58))
        ]
      },
      tags: { "with" => [Span.new("", 3)] },
      filters: { "plus" => [Span.new("", 52)] }
    )
  end

  # TODO: finish me
end
