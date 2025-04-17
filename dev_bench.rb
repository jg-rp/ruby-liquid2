require "benchmark"
require "strscan"

class T
  attr_reader :foo, :bar

  def initialize(foo, bar)
    @foo = foo
    @bar = bar
  end
end

D = Data.define(:foo, :bar)

gss = StringScanner.new("")

n = 1_000_000

Benchmark.bm(10) do |b|
  b.report("Array") do
    n.times do
      t = [:foo, "foo"]
      t.first
      t[1]
    end
  end

  b.report("Tuple") do
    n.times do
      t = [:foo, "foo", 42]
      t.first
      t[1]
      t.last
    end
  end

  b.report("Hash") do
    n.times do
      t = { foo: "bar", bar: "foo" }
      t[:foo]
      t[:bar]
    end
  end

  b.report("Class") do
    n.times do
      t = T.new("foo", "bar")
      t.foo
      t.bar
    end
  end

  b.report("Data") do
    n.times do
      t = D.new("bar", "foo")
      t.foo
      t.bar
    end
  end

  b.report("New scanner") do
    n.times do
      StringScanner.new(+"foobar")
      StringScanner.new(+"barfoo")
    end
  end

  b.report("Same scanner") do
    n.times do
      gss.string = +"foobar"
      gss.string = +"barfoo"
    end
  end
end
