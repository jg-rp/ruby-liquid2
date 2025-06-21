# frozen_string_literal: true

require "json"
require "test_helper"

class MockEnv < Liquid2::Environment
  def setup_tags_and_filters
    super
    register_filter("range", Liquid2::Filters.method(:better_slice))
  end
end

class TestBetterSlice < Minitest::Spec
  make_my_diffs_pretty!

  TEST_CASES = JSON.load_file("test/better_slice.json")

  describe "better slice" do
    TEST_CASES["tests"].each do |test_case|
      it test_case["name"] do
        loader = if (templates = test_case["templates"])
                   Liquid2::HashLoader.new(templates)
                 end

        env = MockEnv.new(loader: loader)

        if test_case["invalid"]
          assert_raises Liquid2::LiquidError do
            env.parse(test_case["template"]).render(test_case["data"])
          end
        else
          template = env.parse(test_case["template"])
          if test_case["result"]
            _(template.render(test_case["data"])).must_equal test_case["result"]
          else
            _(test_case["results"]).must_include template.render(test_case["data"])
          end
        end
      end
    end
  end
end
