# frozen_string_literal: true

require "test_helper"

class MockLoader < Liquid2::HashLoader
  def initialize(templates, matter)
    super(templates)
    @matter = matter
  end

  def get_source(env, name, context: nil, **kwargs)
    source = super
    Liquid2::TemplateSource.new(source: source.source, name: source.name, matter: @matter[name])
  end
end

class TestOverlay < Minitest::Test
  def test_front_matter_loader
    loader = MockLoader.new(
      {
        "some" => "Hello, {{ you }}{{ username }}!",
        "other" => "Goodbye, {{ you }}{{ username }}.",
        "thing" => "{{ you }}{{ username }}"
      },
      {
        "some" => { "you" => "World" },
        "other" => { "username" => "Smith" }
      }
    )

    env = Liquid2::Environment.new(loader: loader)
    template = env.get_template("some")

    assert_equal("Hello, World!", template.render)

    template = env.get_template("other")

    assert_equal("Goodbye, Smith.", template.render)

    template = env.get_template("thing")

    assert_equal("", template.render)
  end

  def test_overlay_data_takes_priority_over_globals
    loader = MockLoader.new(
      { "some" => "Hello, {{ you }}{{ username }}!" },
      { "some" => { "you" => "World" } }
    )

    env = Liquid2::Environment.new(loader: loader, globals: { "you" => "Liquid" })
    template = env.get_template("some", globals: { "you" => "Jinja" })

    assert_equal("Hello, World!", template.render)
  end

  def test_render_data_takes_priority_over_overlay_data
    loader = MockLoader.new(
      { "some" => "Hello, {{ you }}{{ username }}!" },
      { "some" => { "you" => "World" } }
    )

    env = Liquid2::Environment.new(loader: loader)
    template = env.get_template("some")

    assert_equal("Hello, Liquid!", template.render({ "you" => "Liquid" }))
  end
end
