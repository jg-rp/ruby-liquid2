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

  def test_template_not_found
    loader = Liquid2::FileSystemLoader.new("test/cts/benchmark_fixtures/001/templates/")
    env = Liquid2::Environment.new(loader: loader)

    assert_raises(Liquid2::LiquidTemplateNotFoundError) do
      env.get_template("nosuchthing.liquid")
    end
  end

  def test_no_such_search_path
    loader = Liquid2::FileSystemLoader.new("no/such/thing")
    env = Liquid2::Environment.new(loader: loader)

    assert_raises(Liquid2::LiquidTemplateNotFoundError) do
      env.get_template("index.liquid")
    end
  end

  def test_array_of_paths_to_search
    loader = Liquid2::FileSystemLoader.new([
                                             "test/cts/benchmark_fixtures/002/templates/",
                                             "test/cts/benchmark_fixtures/001/templates/"
                                           ])

    env = Liquid2::Environment.new(loader: loader)
    # index.liquid from 002
    template = env.get_template("index.liquid")

    assert_instance_of(Liquid2::Template, template)
    assert_equal("index.liquid", template.name)

    # header.liquid from 001
    template = env.get_template("header.liquid")

    assert_instance_of(Liquid2::Template, template)
    assert_equal("header.liquid", template.name)
  end

  def test_default_file_extension_is_nil
    loader = Liquid2::FileSystemLoader.new("test/cts/benchmark_fixtures/001/templates/")
    env = Liquid2::Environment.new(loader: loader)

    assert_raises(Liquid2::LiquidTemplateNotFoundError) do
      env.get_template("index")
    end
  end

  def test_set_default_file_extension
    loader = Liquid2::FileSystemLoader.new("test/cts/benchmark_fixtures/001/templates/",
                                           default_extension: ".liquid")

    env = Liquid2::Environment.new(loader: loader)
    template = env.get_template("index")

    assert_instance_of(Liquid2::Template, template)
    assert_equal("index.liquid", template.name)
  end

  def test_stay_in_search_path
    loader = Liquid2::FileSystemLoader.new("test/cts/benchmark_fixtures/001/templates/")
    env = Liquid2::Environment.new(loader: loader)

    assert_raises(Liquid2::LiquidTemplateNotFoundError) do
      env.get_template("../../002/templates/index.liquid")
    end
  end

  def test_templates_are_not_cached
    loader = Liquid2::FileSystemLoader.new("test/cts/benchmark_fixtures/001/templates/")
    env = Liquid2::Environment.new(loader: loader)
    template = env.get_template("index.liquid")

    assert_instance_of(Liquid2::Template, template)
    assert_equal("index.liquid", template.name)
    assert_predicate(template, :up_to_date?)

    another_template = env.get_template("index.liquid")

    assert_equal("index.liquid", another_template.name)
    refute_same(template, another_template)
  end
end
