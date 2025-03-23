# frozen_string_literal: true

require "test_helper"

class TestLiquid2 < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Liquid2::VERSION
  end
end
