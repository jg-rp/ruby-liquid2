# frozen_string_literal: true

require "test_helper"

class TestJSONFilter < Minitest::Test
  def test_string_literal
    source = "{{ 'hello' | json }}"
    expect = '"hello"'

    assert_equal(expect, Liquid2.render(source))
  end

  def test_integer_literal
    source = "{{ 42 | json }}"
    expect = "42"

    assert_equal(expect, Liquid2.render(source))
  end

  def test_hash_and_array
    source = "{{ foo | json: pretty=false }}"
    data = { "foo" => { "bar" => [1, 2, 3] } }
    expect = '{"bar":[1,2,3]}'

    assert_equal(expect, Liquid2.render(source, data))
  end
end
