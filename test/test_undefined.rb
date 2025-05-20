# frozen_string_literal: true

require "test_helper"

class TestUndefinedCVariables < Minitest::Test
  def test_falsy_strict_undefined
    source = "{% if nosuchthing %}foo{% else %}bar{% endif %}"
    env = Liquid2::Environment.new(falsy_undefined: true, undefined: Liquid2::StrictUndefined)

    assert_equal("bar", env.render(source))
  end

  def test_disable_falsy_strict_undefined
    source = "{% if nosuchthing %}foo{% else %}bar{% endif %}"
    env = Liquid2::Environment.new(falsy_undefined: false, undefined: Liquid2::StrictUndefined)

    message = "nosuchthing is undefined"
    error = assert_raises(Liquid2::UndefinedError) { env.render(source) }
    assert_equal(message, error.message)
  end

  def test_inline_falsy_strict_undefined
    source = "{{ nosuchthing or \"bar\" }}"
    env = Liquid2::Environment.new(falsy_undefined: true, undefined: Liquid2::StrictUndefined)

    assert_equal("bar", env.render(source))
  end

  def test_disable_inline_falsy_strict_undefined
    source = "{{ nosuchthing or \"bar\" }}"
    env = Liquid2::Environment.new(falsy_undefined: false, undefined: Liquid2::StrictUndefined)

    message = "nosuchthing is undefined"
    error = assert_raises(Liquid2::UndefinedError) { env.render(source) }
    assert_equal(message, error.message)
  end

  def test_ternary_falsy_strict_undefined
    source = "{{ \"foo\" if nosuchthing else \"bar\" }}"
    env = Liquid2::Environment.new(falsy_undefined: true, undefined: Liquid2::StrictUndefined)

    assert_equal("bar", env.render(source))
  end

  def test_disable_ternary_falsy_strict_undefined
    source = "{{ \"foo\" if nosuchthing else \"bar\" }}"
    env = Liquid2::Environment.new(falsy_undefined: false, undefined: Liquid2::StrictUndefined)

    message = "nosuchthing is undefined"
    error = assert_raises(Liquid2::UndefinedError) { env.render(source) }
    assert_equal(message, error.message)
  end

  def test_prefix_coerced_to_undefined
    source = "{{ -'foo' or 'bar' }}"
    env = Liquid2::Environment.new(falsy_undefined: true,
                                   arithmetic_operators: true)

    assert_equal("bar", env.render(source))
  end

  def test_prefix_coerced_to_strict_undefined
    source = "{{ -'foo' or 'bar' }}"
    env = Liquid2::Environment.new(falsy_undefined: true,
                                   undefined: Liquid2::StrictUndefined,
                                   arithmetic_operators: true)

    assert_equal("bar", env.render(source))
  end

  def test_disable_falsy_prefix_coerced_to_undefined
    source = "{{ -'foo' or 'bar' }}"
    env = Liquid2::Environment.new(falsy_undefined: false,
                                   undefined: Liquid2::StrictUndefined,
                                   arithmetic_operators: true)

    message = "\"-(foo)\" is undefined"
    error = assert_raises(Liquid2::UndefinedError) { env.render(source) }
    assert_equal(message, error.message)
  end
end
