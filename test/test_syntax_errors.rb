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
end
