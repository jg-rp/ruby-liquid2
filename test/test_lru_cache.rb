# frozen_string_literal: true

require "test_helper"

class TestLRUCache < Minitest::Test
  def test_expire_cache_key
    cache = Liquid2::LRUCache.new(2)
    cache["a"] = 1
    cache["b"] = 2

    assert_equal(2, cache.length)
    assert_equal(%w[a b], cache.keys)

    cache["c"] = 42

    assert_equal(2, cache.length)
    assert_equal(%w[b c], cache.keys)
  end

  def test_set_an_existing_key
    cache = Liquid2::LRUCache.new(2)
    cache["a"] = 1
    cache["b"] = 2

    assert_equal(2, cache.length)
    assert_equal(%w[a b], cache.keys)
    assert_equal(1, cache["a"])

    cache["a"] = 42

    assert_equal(2, cache.length)
    assert_equal(%w[b a], cache.keys)
    assert_equal(42, cache["a"])

    cache["c"] = 7

    assert_equal(2, cache.length)
    assert_equal(%w[a c], cache.keys)
  end
end

class TestThreadSafeLRUCache < Minitest::Test
  def test_expire_cache_key
    cache = Liquid2::ThreadSafeLRUCache.new(2)
    cache["a"] = 1
    cache["b"] = 2

    assert_equal(2, cache.length)
    assert_equal(%w[a b], cache.keys)

    cache["c"] = 42

    assert_equal(2, cache.length)
    assert_equal(%w[b c], cache.keys)
  end

  def test_set_an_existing_key
    cache = Liquid2::ThreadSafeLRUCache.new(2)
    cache["a"] = 1
    cache["b"] = 2

    assert_equal(2, cache.length)
    assert_equal(%w[a b], cache.keys)
    assert_equal(1, cache["a"])

    cache["a"] = 42

    assert_equal(2, cache.length)
    assert_equal(%w[b a], cache.keys)
    assert_equal(42, cache["a"])

    cache["c"] = 7

    assert_equal(2, cache.length)
    assert_equal(%w[a c], cache.keys)
  end
end
