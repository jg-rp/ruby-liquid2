# frozen_string_literal: true

require "test_helper"

class TestSortNumeric < Minitest::Test
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

  def test_array_of_hashes_with_a_key
    left = [{ "y" => "-1", "x" => "10" }, { "x" => "3" }, { "x" => "2" }, { "x" => "1" }]
    sorted = Liquid2::Filters.sort_numeric(left, "x", context: MOCK_RENDER_CONTEXT)

    assert_equal([{ "x" => "1" }, { "x" => "2" }, { "x" => "3" }, { "y" => "-1", "x" => "10" }],
                 sorted)
  end

  def test_array_of_hashes_with_missing_keys
    left = [{ "y" => "-1", "x" => "10" }, { "x" => "3" }, { "x" => "2" }, { "y" => "1" }]
    sorted = Liquid2::Filters.sort_numeric(left, "x", context: MOCK_RENDER_CONTEXT)

    assert_equal([{ "x" => "2" }, { "x" => "3" }, { "y" => "-1", "x" => "10" }, { "y" => "1" }],
                 sorted)
  end

  def test_string_input
    left = "12345"
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal(["12345"], sorted)
  end

  def test_empty_array_with_key
    left = []
    sorted = Liquid2::Filters.sort_numeric(left, "x", context: MOCK_RENDER_CONTEXT)

    assert_empty(sorted)
  end

  def test_dotted_strings_with_leading_non_digit
    left = ["v1.2", "v1.9", "v10.0", "v1.10", "v1.1.0"]
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal(["v1.1.0", "v1.2", "v1.9", "v1.10", "v10.0"], sorted)
  end

  def test_leading_zeros
    left = %w[107 042 0001 02 17]
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal(%w[0001 02 17 042 107], sorted)
  end

  def test_trailing_non_digits
    left = ["42 Some Street", "7 Some Street", "101 Some Street"]
    sorted = Liquid2::Filters.sort_numeric(left, context: MOCK_RENDER_CONTEXT)

    assert_equal(["7 Some Street", "42 Some Street", "101 Some Street"], sorted)
  end

  def test_not_hashes_with_key
    left = %w[2 1]
    sorted = Liquid2::Filters.sort_numeric(left, "x", context: MOCK_RENDER_CONTEXT)

    assert_equal(%w[2 1], sorted)
  end
end
