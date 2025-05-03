# frozen_string_literal: true

require "test_helper"

class MockDrop
  KEYS = Set["foo", "bar"]

  def [](key)
    send(key) if KEYS.member?(key)
  end

  def key?(key)
    KEYS.member?(key)
  end

  def foo = 42
  def bar = "Hello!"
  def baz = "not public"
  def to_s = "MockDrop"
end

class MockEnumerableDrop
  include Enumerable

  def each
    yield "foo"
    yield "bar"
    yield 42
  end

  def to_s
    "MockEnumerableDrop"
  end

  def first
    "baz"
  end

  def last
    7
  end

  def to_liquid(_context)
    false
  end
end

class MockLazySlicingDrop
  include Enumerable

  def initialize(*items)
    @items = items
  end

  def each
    # Deliberately different items to make sure we're not calling each.
    yield "foo"
    yield "bar"
    yield 42
  end

  def slice(start, length, reversed)
    array = @items.slice(start || 0, length || @items.length)
    reversed ? array.reverse! : array
  end

  def to_s
    "MockLazyDrop"
  end
end

class TestDropAPI < Minitest::Test
  def test_loop_over_an_enumerable
    source = "{% for x in y %}{{ x }},{% endfor %}"
    expect = "foo,bar,42,"
    result = Liquid2.render(source, { "y" => MockEnumerableDrop.new })

    assert_equal(expect, result)
  end

  def test_slice_a_drop
    source = "{% for x in y offset: 2, limit: 5 %}{{ x }},{% endfor %}"
    expect = "2,3,4,5,6,"
    result = Liquid2.render(source, { "y" => MockLazySlicingDrop.new(*(0..10)) })

    assert_equal(expect, result)
  end

  def test_join_an_enumerable
    source = "{{ y | join: '#' }}"
    expect = "foo#bar#42"
    result = Liquid2.render(source, { "y" => MockEnumerableDrop.new })

    assert_equal(expect, result)
  end

  def test_map_an_enumerable
    source = "{{ y | map: i => 'Hello ${i}' | join: ', ' }}"
    expect = "Hello foo, Hello bar, Hello 42"
    result = Liquid2.render(source, { "y" => MockEnumerableDrop.new })

    assert_equal(expect, result)
  end

  def test_first_of_an_object
    source = "{{ x.first }} {{ x | first }}"
    expect = "baz baz"
    result = Liquid2.render(source, { "x" => MockEnumerableDrop.new })

    assert_equal(expect, result)
  end

  def test_last_of_an_object
    source = "{{ x.last }} {{ x | last }}"
    expect = "7 7"
    result = Liquid2.render(source, { "x" => MockEnumerableDrop.new })

    assert_equal(expect, result)
  end

  def test_truthy_to_liquid
    source = "{% if x %}true{% else %}false{% endif %}"
    expect = "true"
    result = Liquid2.render(source, { "x" => MockLazySlicingDrop.new })

    assert_equal(expect, result)
  end

  def test_falsy_to_liquid
    source = "{% if x %}true{% else %}false{% endif %}"
    expect = "false"
    result = Liquid2.render(source, { "x" => MockEnumerableDrop.new })

    assert_equal(expect, result)
  end

  def test_compare_to_liquid
    source = "{% if x == false %}true{% else %}false{% endif %}"
    expect = "true"
    result = Liquid2.render(source, { "x" => MockEnumerableDrop.new })

    assert_equal(expect, result)
  end

  def test_resolve_drop_method
    source = "{{ x.foo }} {{ x.bar }} {{ x.baz }}"
    expect = "42 Hello! "
    result = Liquid2.render(source, { "x" => MockDrop.new })

    assert_equal(expect, result)
  end
end
