# frozen_string_literal: true

require "json"
require "test_helper"

class TestExtends < Minitest::Spec
  make_my_diffs_pretty!

  TEST_CASES = JSON.load_file("test/extends.json")

  describe "extends" do
    TEST_CASES["tests"].each do |test_case|
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

class TestTemplateInheritance < Minitest::Test
  def test_missing_required_block
    source = "{% extends 'foo' %}{% block baz %}{% endblock %}"

    partials = {
      "foo" => "{% block bar required %}{% endblock %}"
    }

    message = "block \"bar\" is required"

    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)
    error = assert_raises(Liquid2::RequiredBlockError) { template.render }
    assert_equal(message, error.message)
  end

  def test_missing_required_block_from_grandparent
    source = "{% extends 'bar' %}"

    partials = {
      "foo" => "{% block baz required %}{% endblock %}",
      "bar" => "{% extends 'foo' %}{% block some %}hello{% endblock %}"
    }

    message = "block \"baz\" is required"

    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)
    error = assert_raises(Liquid2::RequiredBlockError) { template.render }
    assert_equal(message, error.message)
  end

  def test_override_required_block
    source = "{% extends 'foo' %}{% block bar %}hello{% endblock %}"

    partials = {
      "foo" => "{% block bar required %}{% endblock %}"
    }

    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)

    assert_equal("hello", template.render)
  end

  def test_override_required_block_in_grandparent
    source = "{% extends 'foo' %}{% block baz %}hello{% endblock %}"

    partials = {
      "foo" => "{% block baz required %}{% endblock %}",
      "bar" => "{% extends 'foo' %}{% block some %}hello{% endblock %}"
    }

    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)

    assert_equal("hello", template.render)
  end

  def test_override_required_block_in_the_middle_of_the_stack
    source = "{% extends 'bar' %}{% block content %}hello{% endblock %}"

    partials = {
      "foo" => "{% block content %}{% endblock %}",
      "bar" => "{% extends 'foo' %}{% block content required %}{% endblock %}"
    }

    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)

    assert_equal("hello", template.render)
  end

  def test_missing_required_block_in_the_middle_of_the_stack
    source = "{% extends 'bar' %}"

    partials = {
      "foo" => "{% block content %}{% endblock %}",
      "bar" => "{% extends 'foo' %}{% block content required %}{% endblock %}"
    }

    message = "block \"content\" is required"

    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)
    error = assert_raises(Liquid2::RequiredBlockError) { template.render }
    assert_equal(message, error.message)
  end

  def test_render_required_block_directly
    source = "{% block content required %}{% endblock %}"
    message = "block \"content\" is required"
    template = Liquid2.parse(source)
    error = assert_raises(Liquid2::RequiredBlockError) { template.render }
    assert_equal(message, error.message)
  end

  def test_too_many_extends
    source = "{% extends 'foo' %}{% extends 'bar' %}"
    message = "too many 'extends' tags"
    template = Liquid2.parse(source)
    error = assert_raises(Liquid2::TemplateInheritanceError) { template.render }
    assert_equal(message, error.message)
  end

  def test_too_bad_block_name
    source = "{% extends 'foo' %}"
    partials = { "foo" => "{% block 47 %}{% endblock %}" }
    message = "expected a string literal or unquoted word"
    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)
    error = assert_raises(Liquid2::LiquidSyntaxError) { template.render }
    assert_equal(message, error.message)
  end

  def test_undefined_block_drop_property
    source = "{% extends 'foo' %}{% block bar %}{{ block.nosuchthing }} and sue{% endblock %}"
    partials = { "foo" => "hello, {% block bar %}{{ you }}{% endblock %}" }
    message = "block.nosuchthing is undefined"
    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials),
                                   undefined: Liquid2::StrictUndefined)
    template = env.parse(source)
    error = assert_raises(Liquid2::UndefinedError) { template.render }
    assert_equal(message, error.message)
  end

  def test_no_super_block
    source = "hello, {% block bar %}{{ block.super }}{{ you }}{% endblock %}"
    message = "block.super is undefined"
    env = Liquid2::Environment.new(undefined: Liquid2::StrictUndefined)
    template = env.parse(source)
    error = assert_raises(Liquid2::UndefinedError) { template.render }
    assert_equal(message, error.message)
  end

  def test_duplicate_block_names
    source = "{% extends 'foo' %}{% block bar %}{% endblock %}{% block bar %}{% endblock %}"
    partials = { "foo" => "{% block bar %}{% endblock %}" }
    message = "duplicate block \"bar\""
    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)
    error = assert_raises(Liquid2::TemplateInheritanceError) { template.render }
    assert_equal(message, error.message)
  end

  def test_override_nested_block_and_outer_block
    source = <<~LIQUID.chomp
      {% extends "foo" %}
      {% block title %}Home{% endblock %}
      {% block head %}{{ block.super }}Hello{% endblock %}
    LIQUID

    partials = {
      "foo" => <<~LIQUID.chomp
        {% block head %}
        <title>{% block title %}{% endblock %} - Welcome</title>
        {% endblock %}
      LIQUID
    }

    expect = "\n<title>Home - Welcome</title>\nHello"
    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.parse(source)

    assert_equal(expect, template.render)
  end

  def test_recursive_extends
    partials = {
      "some" => "{% extends 'other' %}",
      "other" => "{% extends 'some' %}"
    }

    message = "circular extends \"other\""
    env = Liquid2::Environment.new(loader: Liquid2::HashLoader.new(partials))
    template = env.get_template("some")
    error = assert_raises(Liquid2::TemplateInheritanceError) { template.render }
    assert_equal(message, error.message)
  end
end
