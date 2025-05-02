# frozen_string_literal: true

require_relative "errors"

module Liquid2
  # The default undefined type. Can be iterated over an indexed without error.
  class Undefined
    attr_reader :force_default

    def initialize(name, node: nil)
      @name = name
      @node = node
      @force_default = false
    end

    def [](...) = self
    def key?(...) = false
    def include?(...) = false
    def member?(...) = false
    def fetch(...) = self
    def ! = true
    def ==(other) = other.nil? || other.is_a?(Undefined)
    alias eql? ==
    def size = 0
    def length = 0
    def to_s = ""
    def to_i = 0
    def to_f = 0.0
    def each(...) = Enumerator.new {} # rubocop:disable Lint/EmptyBlock
    def each_with_index(...) = Enumerator.new {} # rubocop:disable Lint/EmptyBlock
    def join(...) = ""
    def to_liquid(_context) = nil
    def poke = true
  end

  # An undefined type that always raises an exception.
  class StrictUndefined < Undefined
    def initialize(name, node: nil)
      super
      @message = "#{name.inspect} is undefined"
    end

    def respond_to_missing? = true

    def method_missing(...)
      raise UndefinedError.new(@message, @node.token)
    end

    def [](...)
      raise UndefinedError.new(@message, @node.token)
    end

    def key?(...)
      raise UndefinedError.new(@message, @node.token)
    end

    def include?(...)
      raise UndefinedError.new(@message, @node.token)
    end

    def member?(...)
      raise UndefinedError.new(@message, @node.token)
    end

    def fetch(...)
      raise UndefinedError.new(@message, @node.token)
    end

    def !
      raise UndefinedError.new(@message, @node.token)
    end

    def ==(_other)
      raise UndefinedError.new(@message, @node.token)
    end

    def !=(_other)
      raise UndefinedError.new(@message, @node.token)
    end

    alias eql? ==

    def size
      raise UndefinedError.new(@message, @node.token)
    end

    def length
      raise UndefinedError.new(@message, @node.token)
    end

    def to_s
      raise UndefinedError.new(@message, @node.token)
    end

    def to_i
      raise UndefinedError.new(@message, @node.token)
    end

    def to_f
      raise UndefinedError.new(@message, @node.token)
    end

    def each(...)
      raise UndefinedError.new(@message, @node.token)
    end

    def each_with_index(...)
      raise UndefinedError.new(@message, @node.token)
    end

    def join(...)
      raise UndefinedError.new(@message, @node.token)
    end

    def to_liquid(_context)
      raise UndefinedError.new(@message, @node.token)
    end

    def poke
      raise UndefinedError.new(@message, @node.token)
    end
  end

  # A strict undefined type that plays nicely with the _default_ filter.
  class StrictDefaultUndefined < StrictUndefined
    def initialize(name, node: nil)
      super
      @force_default = true
    end
  end
end
