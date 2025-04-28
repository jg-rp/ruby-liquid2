# frozen_string_literal: true

require "test_helper"

class TestAPI < Minitest::Test
  def test_parse_from_string
    source = "Hello, {{ you }}!"
    data = { "you" => "World" }
    template = Liquid2.parse(source)

    assert_equal("Hello, World!", template.render(data))
  end

  def test_parse_from_string_with_global_data
    source = "Hello, {{ you }}!"
    data = { "you" => "World" }
    template = Liquid2.parse(source, globals: data)

    assert_equal("Hello, World!", template.render)
  end

  # TODO: finish me
end
