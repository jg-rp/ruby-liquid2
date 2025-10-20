# frozen_string_literal: true

require "test_helper"

class TestLiquidSyntaxErrors < Minitest::Test
  def test_missing_expression
    source = "{% if %}foo{% endif %}"
    message = "missing expression"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_end_tag_mismatch
    source = "{% if true %}foo{% endunless %}"
    message = "unexpected tag \"endunless\""
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_unexpected_tag
    source = "{% foo true %}foo{% endfoo %}"
    message = "unexpected tag \"foo\""
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_tag_name
    source = "{% %}foo{% endif %}"
    message = "missing tag name"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_end_tag_at_eof
    source = "{% if true %}foo{% assign bar = 'baz' %}"
    message = "expected tag endif"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_orphaned_break
    source = "{% break %}"
    message = "unexpected break"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_orphaned_continue
    source = "{% continue %}"
    message = "unexpected continue"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_orphaned_when
    source = "{% when %}"
    message = "unexpected tag \"when\""
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_in
    source = "{% for x (0..3) %}{{ x }}{% endfor %}"
    message = "missing 'in'"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_enumerable_in_forloop
    source = "{% for x in %}{{ x }}foo{% endfor %}"
    message = "missing expression"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_too_many_dots_in_range
    source = "{% for x in (2...4) %}{{ x }}{% endfor %}"
    message = "too many dots"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_loop_identifier_is_a_path
    source = "{% for x.y in (2..4) %}{{ x }}{% endfor %}"
    message = "expected an identifier, found a path"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_assignment_operator
    source = "{% assign x 5 %}"
    message = "malformed identifier or missing assignment operator"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_invalid_bracketed_path
    source = "{{ foo[1.2] }}"
    message = "unexpected token_float"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_hyphen_string
    source = "{{ -'foo' }}"
    message = "unexpected prefix operator -"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_unknown_prefix_operator
    source = "{{ +5 }}"
    message = "unexpected prefix operator +"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_unknown_infix_operator
    source = "{% if 1 =! 2 %}ok{% endif %}"
    message = "unexpected \"=!\""
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_float_without_leading_digit
    source = "{{ .1 }}"
    message = "unexpected token_dot"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_bad_unless_expression
    source = "{% unless 1 ~ 2 %}ok{% endunless %}"
    message = "unexpected token_unknown"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_junk_in_liquid_tag
    source = <<~LIQUID
      {{ 'hello' }}
      {% liquid
      echo 'foo'
      aiu34bseu
      %}
    LIQUID

    message = "unexpected tag \"aiu34bseu\""
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_unexpected_token_between_left_value_and_filter
    source = "{{ \"hello\" boo | upcase }}"
    message = "unexpected token_word"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_extra_else_block
    source = "{% if true %}a{% else %}b{% else %}c{% endif %}"
    message = "unexpected tag else"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_extra_elsif_block
    source = "{% if true %}a{% else %}b{% elsif %}c{% endif %}"
    message = "unexpected tag elsif"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_output_closing_bracket
    source = "Hello, {{you}!"
    message = "missing markup delimiter detected"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_tag_closing_percent
    source = "{% assign x = 42 }"
    message = "missing markup delimiter detected"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_tag_closing_bracket
    source = "{% assign x = 42 %"
    message = "missing markup delimiter detected"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_closing_quote_for_template_string
    source = "{{ \"Hello, ${you} }}"
    message = "unclosed string literal or template string expression"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_missing_closing_bracket_in_template_string
    source = "{{ \"Hello, ${you\" }}"
    message = "unclosed string literal or template string expression"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_path_empty_brackets
    source = "{{ a.b[] }}"
    message = "empty bracketed segment"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_path_unbalanced_brackets
    source = "{{ a.b['foo']] }}"
    message = "unexpected token_rbracket"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_consecutive_commas_in_positional_argument_list
    source = "{% cycle a,, b %}"
    message = "unexpected token_comma"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_consecutive_commas_in_keyword_argument_list
    source = "{% include 'foo' you='world',, some='thing' %}"
    message = "unexpected token_comma"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_assign_to_bad_identifier
    source = "{% assign foo+bar = 'hello there'%}{{ foo+bar }}"
    message = "malformed identifier or missing assignment operator"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end

  def test_unbalanced_parentheses
    source = "{% if true and (false and true %}a{% else %}b{% endif %}"
    message = "unbalanced parentheses"
    error = assert_raises(Liquid2::LiquidSyntaxError) { Liquid2.render(source) }
    assert_equal(message, error.message)
  end
end
