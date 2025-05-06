# frozen_string_literal: true

require "test_helper"

class MockUndefined < Liquid2::Undefined
  def to_s = "UNDEFINED"
end

class TestMacros < Minitest::Test
  def test_define_a_macro
    source = "{% macro 'func' %}Hello, World!{% endmacro %}"

    assert_equal("", Liquid2.render(source))
  end

  def test_define_and_call_a_macro
    source = "{% macro 'func' %}Hello, World!{% endmacro %}{% call 'func' %}"

    assert_equal("Hello, World!", Liquid2.render(source))
  end

  def test_unquoted_macro_names
    source = "{% macro func %}Hello, World!{% endmacro %}{% call 'func' %}{% call func %}"

    assert_equal("Hello, World!Hello, World!", Liquid2.render(source))
  end

  def test_single_positional_argument
    source = <<~LIQUID.chomp
      {% macro func, you %}Hello, {{ you }}!{% endmacro -%}
      {% call func, 'World' %}
      {% call func, 'Liquid' %}
    LIQUID

    assert_equal("Hello, World!\nHello, Liquid!", Liquid2.render(source))
  end

  def test_single_default_argument
    source = <<~LIQUID.chomp
      {% macro func, you='Brian' %}Hello, {{ you }}!{% endmacro -%}
      {% call func %}
      {% call func, 'Liquid' %}
    LIQUID

    assert_equal("Hello, Brian!\nHello, Liquid!", Liquid2.render(source))
  end

  def test_call_default_argument_by_name
    source = <<~LIQUID.chomp
      {% macro func, you='Brian' %}Hello, {{ you }}!{% endmacro -%}
      {% call func %}
      {% call func, you='Liquid' %}
    LIQUID

    assert_equal("Hello, Brian!\nHello, Liquid!", Liquid2.render(source))
  end

  def test_variable_default_argument
    source = <<~LIQUID.chomp
      {% macro func, you=a.b %}Hello, {{ you }}!{% endmacro -%}
      {% call func %}
      {% call func, you='Liquid' %}
    LIQUID

    data = { "a" => { "b" => "Brian" } }

    assert_equal("Hello, Brian!\nHello, Liquid!", Liquid2.render(source, data))
  end

  def test_rest_arguments
    source = <<~LIQUID.chomp
      {% macro func %}{{ args | join: '-' }}{% endmacro -%}
      {% call func 1, 2, 3 %}
    LIQUID

    assert_equal("1-2-3", Liquid2.render(source))
  end

  def test_rest_keyword_arguments
    source = <<~LIQUID.chomp
      {% macro 'func' -%}
      {% for arg in kwargs -%}
      {{ "${arg[0]} => ${arg[1]}, " -}}
      {% endfor -%}
      {% endmacro -%}
      {% call 'func', a: 1, b: 2 %}
    LIQUID

    assert_equal("a => 1, b => 2, ", Liquid2.render(source))
  end

  def test_missing_arguments_are_undefined
    source = <<~LIQUID.chomp
      {% macro func, foo %}{{ foo }}{% endmacro -%}
      {% call func %}
    LIQUID

    env = Liquid2::Environment.new(undefined: MockUndefined)

    assert_equal("UNDEFINED", env.render(source))
  end

  def test_template_assigns_are_out_of_scope
    source = <<~LIQUID.chomp
      {% assign foo = "42" -%}
      {% macro func, foo %}{{ foo }}{% endmacro -%}
      {% call func %}
    LIQUID

    env = Liquid2::Environment.new(undefined: MockUndefined)

    assert_equal("UNDEFINED", env.render(source))
  end

  def test_macro_assigns_go_out_of_scope
    source = <<~LIQUID.chomp
      {% macro func, foo %}{% assign foo = "42" %}{{ foo }}{% endmacro -%}
      {% call func %}
      {{ foo }}!
    LIQUID

    assert_equal("42\n!", Liquid2.render(source))
  end

  def test_undefined_macro
    source = <<~LIQUID.chomp
      {% call func %}
    LIQUID

    env = Liquid2::Environment.new(undefined: MockUndefined)

    assert_equal("UNDEFINED", env.render(source))
  end

  def test_default_argument_before_positional
    source = <<~LIQUID.chomp
      {% macro 'func' you: 'brian', greeting -%}
      {{ greeting }}, {{ you }}!
      {% endmacro -%}
      {% call 'func' -%}
      {% call 'func' you: 'World', greeting: 'Goodbye' %}
    LIQUID

    assert_equal(", brian!\nGoodbye, World!\n", Liquid2.render(source))
  end

  def test_trailing_commas
    source = <<~LIQUID.chomp
      {% macro func, you, %}Hello, {{ you }}!{% endmacro -%}
      {% call func, 'World', %}
      {% call func, 'Liquid', %}
    LIQUID

    assert_equal("Hello, World!\nHello, Liquid!", Liquid2.render(source))
  end
end
