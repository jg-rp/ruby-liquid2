# frozen_string_literal: true

require "json"
require "test_helper"

class TestCompliance < Minitest::Spec
  make_my_diffs_pretty!

  # TEST_CASES = JSON.load_file("test/cts/cts.json")
  TEST_CASES = JSON.load_file("test/cts/tests/identifiers.json")

  describe "render template" do
    TEST_CASES["tests"].each do |test_case|
      it test_case["name"] do
        loader = if (templates = test_case["templates"])
                   Liquid2.HashLoader.new(templates)
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
