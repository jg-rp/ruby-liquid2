# frozen_string_literal: true

require "test_helper"

class TestEscapedStrings < Minitest::Test
  def test_escaped_u0020
    assert_equal(" ", Liquid2.render("{{ '\\u0020' }}"))
  end

  def test_escaped_code_point
    assert_equal("☺", Liquid2.render("{{ '\\u263A' }}"))
  end

  def test_escaped_surrogate_pair
    assert_equal("𝄞", Liquid2.render("{{ '\\uD834\\uDD1E' }}"))
  end

  def test_escaped_double_quote
    data = { "a" => { '"' => "b" } }

    assert_equal("b", Liquid2.render('{{ a["\\""] }}', data))
  end

  def test_escaped_single_quote
    data = { "a" => { "'" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\''] }}", data))
  end

  def test_escaped_reverse_solidus
    data = { "a" => { "\\" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\\\'] }}", data))
  end

  def test_escaped_solidus
    data = { "a" => { "/" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\/'] }}", data))
  end

  def test_escaped_backspace
    data = { "a" => { "\u0008" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\b'] }}", data))
  end

  def test_escaped_line_feed
    data = { "a" => { "\n" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\n'] }}", data))
  end

  def test_escaped_carriage_return
    data = { "a" => { "\r" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\r'] }}", data))
  end

  def test_escaped_tab
    data = { "a" => { "\t" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\t'] }}", data))
  end

  def test_escaped_form_feed
    data = { "a" => { "\u000c" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\f'] }}", data))
  end

  def test_unescape_form_feed
    data = { "a" => { "\f" => "b" } }

    assert_equal("b", Liquid2.render("{{ a['\\u000c'] }}", data))
  end

  def test_escaped_code_point_in_path
    data = { "a" => { "☺" => "b" } }

    assert_equal("b", Liquid2.render('{{ a["\\u263A"] }}', data))
  end

  def test_escaped_surrogate_pair_in_path
    data = { "a" => { "𝄞" => "b" } }

    assert_equal("b", Liquid2.render('{{ a["\\uD834\\uDD1E"] }}', data))
  end

  def test_unicode_identifier
    assert_equal("smiley", Liquid2.render("{% assign ☺ = 'smiley' %}{{ ☺ }}"))
  end

  def test_escaped_double_quote_in_single_quote_string
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['\\\"'] }}")
    end
  end

  def test_unknown_escape_sequence
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['\\xc'] }}")
    end
  end

  def test_incomplete_escape
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['\\'] }}")
    end
  end

  def test_incomplete_code_point
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['\\u263'] }}")
    end
  end

  def test_incomplete_surrogate_pair
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['\\uD83D\\uDE0'] }}")
    end
  end

  def test_two_high_surrogates
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['\\uD800\\uD800'] }}")
    end
  end

  def test_high_surrogate_followed_by_non_surrogate
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['\\uD800\\u263Ac'] }}")
    end
  end

  def test_just_a_low_surrogate
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['ab\\uDC00c'] }}")
    end
  end

  def test_non_hex_digits_code_point
    assert_raises(Liquid2::LiquidSyntaxError) do
      Liquid2.parse("{{ a['ab\\u263Xc'] }}")
    end
  end
end
