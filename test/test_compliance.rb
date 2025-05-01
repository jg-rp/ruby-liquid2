# frozen_string_literal: true

require "json"
require "test_helper"

class TestCompliance < Minitest::Spec
  make_my_diffs_pretty!

  TEST_CASES = JSON.load_file("test/golden_liquid/golden_liquid.json")

  # rubocop:disable Layout/LineLength
  SKIP = Set[
    "tags, unless, extra elsif blocks are ignored",
    "tags, unless, extra else blocks are ignored",
    "tags, unless, else tag expressions are ignored",
    "tags, if, extra elsif blocks are ignored",
    "tags, if, extra else blocks are ignored",
    "tags, if, else tag expressions are ignored",
    "tags, ifchanged, change from assign",
    "tags, ifchanged, changed from initial state",
    "tags, ifchanged, not changed from initial state",
    "tags, ifchanged, no change from assign",
    "tags, ifchanged, within for loop",
    "identifiers, capture only digits",
    "identifiers, only digits",
    "identifiers, trailing question mark in for loop target",
    "identifiers, trailing question mark in for loop variable",
    "identifiers, trailing question mark output",
    "whitespace control, don't suppress whitespace only blocks containing output in unreachable blocks",
    "whitespace control, don't suppress whitespace only case blocks containing output",
    "filters, find, array of hashes, with a nil",
    "filters, find, mixed array, default value",
    "filters, find index, mixed array, default value",
    "filters, has, array of hashes, with a nil",
    "filters, has, array of ints, default value",
    "filters, has, array of ints, string argument, default value",
    "filters, has, mixed array, default value",
    "filters, map, argument is explicit nil",
    "filters, map, undefined argument",
    "filters, reject, array containing an int, default value",
    "filters, reject, array containing null, default value",
    "filters, slice, first argument is a float",
    "filters, slice, second argument is a float",
    "filters, slice, undefined first argument",
    "filters, sum, properties arguments with non-hash items",
    "filters, truncate, undefined first argument",
    "filters, truncatewords, undefined first argument",
    "filters, where, left value is not an array",
    "tags, case, evaluate multiple matching blocks",
    "tags, case, falsy when before and truthy when after else",
    "tags, case, falsy when before and truthy when after multiple else blocks",
    "tags, case, mix or and comma separated when expression",
    "tags, case, multiple else blocks",
    "tags, case, truthy when before and after else",
    "tags, case, unexpected when token",
    "tags, comment, incomplete tags are not parsed",
    "tags, comment, malformed tags are not parsed",
    "tags, for, limit is a non-number string",
    "tags, for, limit is not a string or number",
    "tags, for, loop over a string literal",
    "tags, for, loop over a string variable",
    "tags, for, offset is a non-number string",
    "tags, for, offset is not a string or number",
    "tags, if, array contains false",
    "tags, if, array contains nil",
    "tags, if, in is not a valid operator",
    "tags, if, logical operators are right associative",
    "tags, if, not is not a valid operator",
    "tags, liquid, liquid tag in liquid tag",
    "tags, liquid, nested liquid in liquid tag"
  ].freeze
  # rubocop:enable Layout/LineLength

  describe "golden liquid" do
    TEST_CASES["tests"].reject { |t| SKIP.include?(t["name"]) }.each do |test_case|
      it test_case["name"] do
        loader = if (templates = test_case["templates"])
                   Liquid2::HashLoader.new(templates)
                 end

        env = Liquid2::Environment.new(loader: loader)
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
