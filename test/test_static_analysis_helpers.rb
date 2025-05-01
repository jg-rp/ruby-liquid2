# frozen_string_literal: true

require "test_helper"

class TestStaticAnalysisHelpers < Minitest::Test
  SOURCE = <<~LIQUID
    Hello, {{ you }}!
    {% assign x = 'foo' | upcase %}
    {% for ch in x %}
        - {{ ch }}
    {% endfor %}
    Goodbye, {{ you.first_name | capitalize }} {{ you.last_name }}
    Goodbye, {{ you.first_name }} {{ you.last_name }}
  LIQUID

  TEMPLATE = Liquid2.parse(SOURCE)

  def test_get_variables
    assert_equal(%w[you x ch], TEMPLATE.variables)
  end

  def test_get_paths
    assert_equal([
      "you",
      "x",
      "ch",
      "you.first_name",
      "you.last_name"
    ].sort!, TEMPLATE.variable_paths.sort!)
  end

  def test_get_segments
    assert_equal([
      ["you"],
      ["x"],
      ["ch"],
      %w[you first_name],
      %w[you last_name]
    ].sort!, TEMPLATE.variable_segments.sort!)
  end

  def test_get_global_variables
    assert_equal(%w[you], TEMPLATE.global_variables)
  end

  def test_get_global_paths
    assert_equal([
      "you",
      "you.first_name",
      "you.last_name"
    ].sort!, TEMPLATE.global_variable_paths.sort!)
  end

  def test_get_global_segments
    assert_equal([
      ["you"],
      %w[you first_name],
      %w[you last_name]
    ].sort!, TEMPLATE.global_variable_segments.sort!)
  end

  def test_get_filter_names
    assert_equal(%w[upcase capitalize], TEMPLATE.filter_names)
  end

  def test_get_tag_names
    assert_equal(%w[assign for], TEMPLATE.tag_names)
  end
end
