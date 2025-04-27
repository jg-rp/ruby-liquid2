# frozen_string_literal: true

require "json"
require "test_helper"

class TestCompliance < Minitest::Spec
  make_my_diffs_pretty!
  i_suck_and_my_tests_are_order_dependent!

  TEST_CASES = JSON.load_file("test/golden_liquid/golden_liquid.json")

  SKIP = {
    "tags, unless, extra elsif blocks are ignored" => "policy of least surprise",
    "tags, unless, extra else blocks are ignored" => "policy of least surprise",
    "tags, unless, else tag expressions are ignored" => "policy of least surprise",
    "tags, if, extra elsif blocks are ignored" => "policy of least surprise",
    "tags, if, extra else blocks are ignored" => "policy of least surprise",
    "tags, if, else tag expressions are ignored" => "policy of least surprise"
  }.freeze

  describe "golden liquid" do
    TEST_CASES["tests"].each do |test_case|
      it test_case["name"] do
        skip(SKIP[test_case["name"]]) if SKIP.include?(test_case["name"])

        loader = if (templates = test_case["templates"])
                   Liquid2::HashLoader.new(templates)
                 end

        env = Liquid2::Environment.new(loader: loader, mode: :strict)
        if test_case["invalid"]
          assert_raises Liquid2::LiquidError do
            env.parse(test_case["template"]).render(test_case["data"])
          end
        else
          template = env.parse(test_case["template"])
          _(template.render(test_case["data"])).must_equal(test_case["result"])
        end
      end
    end
  end
end
