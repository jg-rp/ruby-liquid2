# frozen_string_literal: true

require "test_helper"

class TestChainHash < Minitest::Test
  MOCK_RENDER_CONTEXT = Liquid2::RenderContext.new(Liquid2.parse(""))

  def test_empty_array
    left = []
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_empty(sorted)
  end

  def test_array_of_string_integers
    left = %w[10 3 2 1]
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal(%w[1 2 3 10], sorted)
  end

  def test_array_of_integers
    left = [10, 3, 2, 1]
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal([1, 2, 3, 10], sorted)
  end

  def test_array_of_floats
    left = [10.1, 3.5, 2.3, 1.1, 1.01]
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal([1.01, 1.1, 2.3, 3.5, 10.1], sorted)
  end

  def test_negative_strings
    left = ["1", "-1"]
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal(["-1", "1"], sorted)
  end

  def test_left_is_not_enumerable
    left = nil
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal([nil], sorted)
  end

  def test_array_of_hashes_without_a_key
    left = [{ "y" => "-1", "x" => "10" }, { "x" => "3" }, { "x" => "2" }, { "x" => "1" }]
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal([{ "y" => "-1", "x" => "10" }, { "x" => "1" }, { "x" => "2" }, { "x" => "3" }],
                 sorted)
  end

  # TODO: finish me
end
