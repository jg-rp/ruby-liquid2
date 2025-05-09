# frozen_string_literal: true

require "test_helper"

class TestPathToS < Minitest::Test
  def test_simple_variable
    source = "{{ foo }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("foo", path.to_s)
  end

  def test_dotted_variable
    source = "{{ foo.bar }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("foo.bar", path.to_s)
  end

  def test_bracket_notation_with_space
    source = "{{ foo['b c'] }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("foo[\"b c\"]", path.to_s)
  end

  def test_bracket_notation_with_space_at_root
    source = "{{ ['a b'] }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("[\"a b\"]", path.to_s)
  end

  def test_bracket_notation_with_quoted_dot_at_root
    source = "{{ [\"a.b\"] }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("[\"a.b\"]", path.to_s)
  end

  def test_bracket_notation_with_array_index
    source = "{{ a[1] }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("a[1]", path.to_s)
  end

  def test_bracket_notation_with_nested_path
    source = "{{ a[b.c] }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("a[b.c]", path.to_s)
  end

  def test_bracket_notation_with_deeply_nested_path
    source = "{{ d[a[b.c]] }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("d[a[b.c]]", path.to_s)
  end

  def test_bracket_notation_with_nested_path_at_root
    source = "{{ [a.b] }}"
    template = Liquid2.parse(source)
    path = template.ast.first.expression.children.first

    assert_equal("[a.b]", path.to_s)
  end
end
