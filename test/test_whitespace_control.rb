# frozen_string_literal: true

require "test_helper"

class TestWhitespaceControl < Minitest::Test
  def test_no_whitespace_control
    source = <<~LIQUID
      <ul>
      {% for x in (1..4) %}
        <li>{{ x }}</li>
      {% endfor %}
      </ul>
    LIQUID

    expect = <<~LIQUID
      <ul>\n
        <li>1</li>\n
        <li>2</li>\n
        <li>3</li>\n
        <li>4</li>\n
      </ul>
    LIQUID

    assert_equal(expect, Liquid2.render(source))
  end

  def test_tilde
    source = <<~LIQUID
      <ul>
      {% for x in (1..4) ~%}
        <li>{{ x }}</li>
      {% endfor -%}
      </ul>
    LIQUID

    expect = <<~LIQUID
      <ul>
        <li>1</li>
        <li>2</li>
        <li>3</li>
        <li>4</li>
      </ul>
    LIQUID

    assert_equal(expect, Liquid2.render(source))
  end

  def test_auto_trim_tilde
    source = <<~LIQUID
      <ul>
      {% for x in (1..4) %}
        <li>{{ x }}</li>
      {% endfor %}
      </ul>
    LIQUID

    expect = <<~LIQUID
      <ul>
        <li>1</li>
        <li>2</li>
        <li>3</li>
        <li>4</li>
      </ul>
    LIQUID

    env = Liquid2::Environment.new(auto_trim: "~")

    assert_equal(expect, env.render(source))
  end

  def test_auto_trim_hyphen
    source = <<~LIQUID
      <ul>
      {% for x in (1..4) %}
        <li>{{ x }}</li>
      {% endfor %}
      </ul>
    LIQUID

    expect = <<~LIQUID
      <ul>
      <li>1</li>
      <li>2</li>
      <li>3</li>
      <li>4</li>
      </ul>
    LIQUID

    env = Liquid2::Environment.new(auto_trim: "-")

    assert_equal(expect, env.render(source))
  end

  def test_override_auto_trim
    source = <<~LIQUID
      <ul>
      {% for x in (1..4) ~%}
        <li>{{ x }}</li>
      {% endfor %}
      </ul>
    LIQUID

    expect = <<~LIQUID
      <ul>
        <li>1</li>
        <li>2</li>
        <li>3</li>
        <li>4</li>
      </ul>
    LIQUID

    env = Liquid2::Environment.new(auto_trim: "-")

    assert_equal(expect, env.render(source))
  end

  def test_override_auto_trim_with_plus
    source = <<~LIQUID
      <ul>
      {% for x in (1..4) +%}
        <li>{{ x }}</li>
      {% endfor +%}
      </ul>
    LIQUID

    expect = <<~LIQUID
      <ul>\n
        <li>1</li>\n
        <li>2</li>\n
        <li>3</li>\n
        <li>4</li>\n
      </ul>
    LIQUID

    env = Liquid2::Environment.new(auto_trim: "-")

    assert_equal(expect, env.render(source))
  end
end
