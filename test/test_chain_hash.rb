# frozen_string_literal: true

require "test_helper"

class TestChainHash < Minitest::Test
  def test_later_hashes_take_priority
    scope = Liquid2::ReadOnlyChainHash.new({ foo: 1 }, { foo: 2 })

    assert_equal(2, scope[:foo])
  end

  def test_fall_back_to_earlier_hashes
    scope = Liquid2::ReadOnlyChainHash.new({ foo: 1 }, { bar: 2 })

    assert_equal(1, scope[:foo])
  end

  def test_missing_key
    scope = Liquid2::ReadOnlyChainHash.new({ foo: 1 }, { foo: 2 })

    assert_nil(scope[:bar])
  end

  def test_fetch_default
    scope = Liquid2::ReadOnlyChainHash.new({ foo: 1 }, { foo: 2 })

    assert_equal(:undefined, scope.fetch(:bar))
  end

  def test_fetch_with_default
    scope = Liquid2::ReadOnlyChainHash.new({ foo: 1 }, { foo: 2 })

    assert_equal(42, scope.fetch(:bar, default: 42))
  end

  def test_push_scope
    scope = Liquid2::ReadOnlyChainHash.new({ foo: 1 }, { foo: 2 })
    scope.push({ foo: 99 })

    assert_equal(99, scope.fetch(:foo))
  end

  def test_poo_scope
    scope = Liquid2::ReadOnlyChainHash.new({ foo: 1 }, { foo: 2 })
    scope.pop

    assert_equal(1, scope.fetch(:foo))
  end
end
