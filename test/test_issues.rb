# frozen_string_literal: true

require "test_helper"

class TestIssues < Minitest::Test
  def test_issue13
    source = "{{ true.foo }} {{ false.foo }} {{ nil.foo }} {{ null.foo }} {{ and.foo }}"
    data = { "true" => { "foo" => 42 },
             "false" => { "foo" => 43 },
             "nil" => { "foo" => 44 },
             "null" => { "foo" => 45 },
             "and" => { "foo" => 46 } }

    assert_equal("42 43 44 45 46", Liquid2.render(source, data))
  end
end
