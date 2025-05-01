# frozen_string_literal: true

require "test_helper"

class TestResourceLimits < Minitest::Test
  def test_recursive_render
    loader = Liquid2::HashLoader.new(
      {
        "foo" => "{% render 'bar' %}",
        "bar" => "{% render 'foo' %}"
      }
    )

    env = Liquid2::Environment.new(loader: loader)
    template = env.parse("{% render 'foo' %}")
    error = assert_raises(Liquid2::LiquidResourceLimitError) { template.render }

    assert_equal("context depth limit reached", error.message)
  end

  def test_recursive_include
    loader = Liquid2::HashLoader.new(
      {
        "foo" => "{% include 'bar' %}",
        "bar" => "{% include 'foo' %}"
      }
    )

    env = Liquid2::Environment.new(loader: loader)
    template = env.parse("{% include 'foo' %}")
    error = assert_raises(Liquid2::LiquidResourceLimitError) { template.render }

    assert_equal("context depth limit reached", error.message)
  end

  def test_set_context_depth_limit
    loader = Liquid2::HashLoader.new(
      {
        "foo" => "{% render 'bar' %}",
        "bar" => "{% render 'baz' %}",
        "baz" => "Hello"
      }
    )

    env = Liquid2::Environment.new(loader: loader)
    template = env.parse("{% render 'foo' %}")

    assert_equal("Hello", template.render)

    env = Liquid2::Environment.new(loader: loader, context_depth_limit: 3)
    template = env.parse("{% render 'foo' %}")
    error = assert_raises(Liquid2::LiquidResourceLimitError) { template.render }

    assert_equal("context depth limit reached", error.message)
  end

  def test_set_loop_iteration_limit
    env = Liquid2::Environment.new(loop_iteration_limit: 10_000)

    source = <<~LIQUID
      {% for i in (1..100) %}
      {% for j in (1..100) %}
      {{ i }},{{ j }}
      {% endfor %}
      {% endfor %}
    LIQUID

    # No exception is raised. We are within the limit.
    env.render(source)

    source = <<~LIQUID
      {% for i in (1..101) %}
      {% for j in (1..100) %}
      {{ i }},{{ j }}
      {% endfor %}
      {% endfor %}
    LIQUID

    error = assert_raises(Liquid2::LiquidResourceLimitError) { env.render(source) }

    assert_equal("loop iteration limit reached", error.message)
  end

  def test_render_carries_loop_count
    source = <<~LIQUID
      {% for i in (1..50) %}
      {% for j in (1..50) %}
      {{ i }},{{ j }}
      {% endfor %}
      {% endfor %}
    LIQUID

    loader = Liquid2::HashLoader.new({ "foo" => source })
    env = Liquid2::Environment.new(loader: loader, loop_iteration_limit: 3000)
    template = env.parse("{% for i in (1..10) %}{% render 'foo' %}{% endfor %}")
    error = assert_raises(Liquid2::LiquidResourceLimitError) { template.render }

    assert_equal("loop iteration limit reached", error.message)
  end

  def test_include_carries_loop_count
    source = <<~LIQUID
      {% for i in (1..50) %}
      {% for j in (1..50) %}
      {{ i }},{{ j }}
      {% endfor %}
      {% endfor %}
    LIQUID

    loader = Liquid2::HashLoader.new({ "foo" => source })
    env = Liquid2::Environment.new(loader: loader, loop_iteration_limit: 3000)
    template = env.parse("{% for i in (1..10) %}{% include 'foo' %}{% endfor %}")
    error = assert_raises(Liquid2::LiquidResourceLimitError) { template.render }

    assert_equal("loop iteration limit reached", error.message)
  end

  def test_set_local_namespace_limit
    env = Liquid2::Environment.new(local_namespace_limit: 5)

    source = <<~LIQUID
      {% assign a = 1 %}
      {% assign b = 2 %}
      {% assign c = 3 %}
      {% assign d = 4 %}
      {% assign e = 5 %}
    LIQUID

    # No exception is raised. We are within the limit.
    env.render(source)

    source = <<~LIQUID
      {% assign a = 1 %}
      {% assign b = 2 %}
      {% assign c = 3 %}
      {% assign d = 4 %}
      {% assign e = 5 %}
      {% assign f = 6 %}
    LIQUID

    error = assert_raises(Liquid2::LiquidResourceLimitError) { env.render(source) }

    assert_equal("local namespace limit reached", error.message)
  end

  def test_render_carries_namespace_score
    source = <<~LIQUID
      {% assign a = 1 %}
      {% assign b = 2 %}
      {% assign c = 3 %}
      {% assign d = 4 %}
      {% assign e = 5 %}
    LIQUID

    loader = Liquid2::HashLoader.new({ "foo" => source })
    env = Liquid2::Environment.new(loader: loader, local_namespace_limit: 5)

    # No exception is raised. We are within the limit.
    env.render("{% render 'foo' %}")

    error = assert_raises(Liquid2::LiquidResourceLimitError) do
      env.render("{% assign f = 6 %}{% render 'foo' %}")
    end

    assert_equal("local namespace limit reached", error.message)
  end

  def test_set_output_stream_limit
    env = Liquid2::Environment.new(output_stream_limit: 5)

    # No exception is raised. We are within the limit.
    env.render("{% if false %}some literal that is longer then the limit{% endif %}hello")

    error = assert_raises(Liquid2::LiquidResourceLimitError) do
      env.render("{% if true %}some literal that is longer then the limit{% endif %}hello")
    end

    assert_equal("output limit reached", error.message)
  end
end
