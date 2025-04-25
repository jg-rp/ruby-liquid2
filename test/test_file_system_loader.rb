# frozen_string_literal: true

require "test_helper"

class TestFileSystemLoader < Minitest::Test
  make_my_diffs_pretty!

  def test_load_template
    loader = Liquid2::FileSystemLoader.new("test/cts/benchmark_fixtures/001/templates/")
    env = Liquid2::Environment.new(loader: loader)
    template = env.get_template("index.liquid")

    assert_instance_of(Liquid2::Template, template)
    assert_equal("index.liquid", template.name)
  end

  # TODO: finish me
end
