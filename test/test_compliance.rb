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
    "tags, if, else tag expressions are ignored" => "policy of least surprise",
    "tags, ifchanged, change from assign" => "",
    "tags, ifchanged, changed from initial state" => "",
    "tags, ifchanged, not changed from initial state" => "",
    "tags, ifchanged, no change from assign" => "",
    "tags, ifchanged, within for loop" => "",
    "identifiers, capture only digits" => "",
    "identifiers, only digits" => "",
    "identifiers, trailing question mark in for loop target" => "",
    "identifiers, trailing question mark in for loop variable" => "",
    "identifiers, trailing question mark output" => "",
    "whitespace control, don't suppress whitespace only blocks containing output in unreachable blocks" => "",
    "whitespace control, don't suppress whitespace only case blocks containing output" => "",
    "filters, find, array of hashes, with a nil" => "",
    "filters, find, mixed array, default value" => "",
    "filters, find index, mixed array, default value" => "",
    "filters, has, array of hashes, with a nil" => "",
    "filters, has, array of ints, default value" => "",
    "filters, has, array of ints, string argument, default value" => "",
    "filters, has, mixed array, default value" => "",
    "filters, map, argument is explicit nil" => "",
    "filters, map, undefined argument" => "",
    "filters, reject, array containing an int, default value" => "",
    "filters, reject, array containing null, default value" => "",
    "filters, slice, first argument is a float" => "",
    "filters, slice, second argument is a float" => "",
    "filters, slice, undefined first argument" => "",
    "filters, sum, properties arguments with non-hash items" => ""
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
