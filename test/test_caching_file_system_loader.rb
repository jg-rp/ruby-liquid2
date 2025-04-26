# frozen_string_literal: true

require "pathname"
require "tmpdir"
require "test_helper"

class TestCachingFileSystemLoader < Minitest::Test
  make_my_diffs_pretty!

  def test_cache_templates
    loader = Liquid2::CachingFileSystemLoader.new("test/cts/benchmark_fixtures/001/templates/")
    env = Liquid2::Environment.new(loader: loader)
    template = env.get_template("index.liquid")

    assert_instance_of(Liquid2::Template, template)
    assert_equal("index.liquid", template.name)
    assert_predicate(template, :up_to_date?)

    another_template = env.get_template("index.liquid")

    assert_same(template, another_template)
  end

  def test_auto_reload_template
    f = Tempfile.create
    p = Pathname.new(f.path)
    p.write("Hello, {{ you }}!")

    loader = Liquid2::CachingFileSystemLoader.new(p.dirname, auto_reload: true)
    env = Liquid2::Environment.new(loader: loader, globals: { "you" => "World" })
    template = env.get_template(p.basename)

    assert_equal("Hello, World!", template.render)
    assert_predicate(template, :up_to_date?)

    sleep(0.01)
    p.write("Goodbye, {{ you }}!")

    refute_predicate(template, :up_to_date?)

    updated_template = env.get_template(p.basename)

    assert_equal("Goodbye, World!", updated_template.render)
    refute_same(template, updated_template)

    p.delete
  end

  def test_disable_auto_reload_template
    f = Tempfile.create
    p = Pathname.new(f.path)
    p.write("Hello, {{ you }}!")

    loader = Liquid2::CachingFileSystemLoader.new(p.dirname, auto_reload: false)
    env = Liquid2::Environment.new(loader: loader, globals: { "you" => "World" })
    template = env.get_template(p.basename)

    assert_equal("Hello, World!", template.render)
    assert_predicate(template, :up_to_date?)

    sleep(0.01)
    p.write("Goodbye, {{ you }}!")

    refute_predicate(template, :up_to_date?)

    reloaded_template = env.get_template(p.basename)

    assert_equal("Hello, World!", reloaded_template.render)
    assert_same(template, reloaded_template)

    p.delete
  end
end
