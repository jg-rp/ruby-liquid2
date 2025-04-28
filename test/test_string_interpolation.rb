# frozen_string_literal: true

require "test_helper"

class TestStringInterpolation < Minitest::Test
  def test_output_single_quoted
    source = "{{ 'Hello, ${you}!' }}"
    data = { "you" => "World" }

    assert_equal("Hello, World!", Liquid2.render(source, data))
  end

  def test_output_double_quoted
    source = "{{ \"Hello, ${you}!\" }}"
    data = { "you" => "World" }

    assert_equal("Hello, World!", Liquid2.render(source, data))
  end

  def test_output_path
    source = "{{ \"Hello, ${you.there}!\" }}"
    data = { "you" => { "there" => "World" } }

    assert_equal("Hello, World!", Liquid2.render(source, data))
  end

  def test_output_path_with_double_quoted_property
    source = "{{ \"Hello, ${you[\"there\"]}!\" }}"
    data = { "you" => { "there" => "World" } }

    assert_equal("Hello, World!", Liquid2.render(source, data))
  end

  def test_output_path_with_single_quoted_property
    source = "{{ \"Hello, ${you['there']}!\" }}"
    data = { "you" => { "there" => "World" } }

    assert_equal("Hello, World!", Liquid2.render(source, data))
  end

  def test_output_expression_at_end_of_string
    source = "{{ \"Hello, ${you}\" }}"
    data = { "you" => "World" }

    assert_equal("Hello, World", Liquid2.render(source, data))
  end

  def test_output_expression_at_start_of_string
    source = "{{ \"${you}!\" }}"
    data = { "you" => "World" }

    assert_equal("World!", Liquid2.render(source, data))
  end

  def test_output_just_expression
    source = "{{ \"${you}\" }}"
    data = { "you" => "World" }

    assert_equal("World", Liquid2.render(source, data))
  end

  def test_echo_single_quoted
    source = "{% echo 'Hello, ${you}!' %}"
    data = { "you" => "World" }

    assert_equal("Hello, World!", Liquid2.render(source, data))
  end

  def test_echo_double_quoted
    source = "{% echo \"Hello, ${you}!\" %}"
    data = { "you" => "World" }

    assert_equal("Hello, World!", Liquid2.render(source, data))
  end

  def test_output_filtered_expression
    source = "{{ 'Hello, ${you | append: '!'}' }}"
    data = { "you" => "World" }

    assert_equal("Hello, World!", Liquid2.render(source, data))
  end

  def test_filter_argument
    source = "{{ 'Hello ' | append: 'there, ${you}!' }}"
    data = { "you" => "World" }

    assert_equal("Hello there, World!", Liquid2.render(source, data))
  end

  def test_ternary_alternative
    source = "{{ 'Hello' if not you else 'Hello there, ${you}!' }}"
    data = { "you" => "World" }

    assert_equal("Hello there, World!", Liquid2.render(source, data))
  end

  def test_infix_left
    source = "{% if 'Hello, ${you}' == 'Hello, World' %}true{% endif %}"
    data = { "you" => "World" }

    assert_equal("true", Liquid2.render(source, data))
  end

  def test_infix_right
    source = "{% if 'Hello, World' == 'Hello, ${you}' %}true{% endif %}"
    data = { "you" => "World" }

    assert_equal("true", Liquid2.render(source, data))
  end

  def test_output_escaped
    source = "{{ 'Hello, \\${you}!' }}"
    data = { "you" => "World" }

    assert_equal("Hello, ${you}!", Liquid2.render(source, data))
  end

  def test_output_nested
    source = "{{ 'Hello, ${you | append: '${something}'}!' }}"
    data = { "you" => "World", "something" => " and Liquid" }

    assert_equal("Hello, World and Liquid!", Liquid2.render(source, data))
  end
end
