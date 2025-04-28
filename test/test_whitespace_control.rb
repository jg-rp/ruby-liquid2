# frozen_string_literal: true

require "test_helper"

class TestWhitespaceControl < Minitest::Test
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
end
