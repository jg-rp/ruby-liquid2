# frozen_string_literal: true

require "test_helper"

class TestWith < Minitest::Test
  def test_block_scoped_variables
    source = <<~LIQUID.chomp
      {% with a: 1, b: 3.4 -%}
      {{ a }} + {{ b }} = {{ a | plus: b }}
      {%- endwith -%}
      {{ a }}
    LIQUID

    assert_equal("1 + 3.4 = 4.4", Liquid2.render(source))
  end

  def test_compound_expression
    source = <<~LIQUID.chomp
      {% with a: 1, b: nosuchthing or 42, c="hi" -%}
      {{ a }} + {{ b }} = {{ a | plus: b }}
      {%- endwith -%}
      {{ a }}
    LIQUID

    assert_equal("1 + 42 = 43", Liquid2.render(source))
  end
end
