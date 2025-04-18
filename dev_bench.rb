require "benchmark/ips"
require "strscan"

class T
  attr_reader :foo, :bar

  def initialize(foo, bar)
    @foo = foo
    @bar = bar
  end
end

class A < Array
  def kind = first
  def value = self[1]
  def start_index = last
end

Token = Struct.new("Token", :foo, :bar)

D = Data.define(:foo, :bar)

gss = StringScanner.new("")

Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)

  x.report("Array") do
    t = [:foo, "foo"]
    t.first
    t[1]
  end

  x.report("Tuple") do
    t = [:foo, "foo", 42]
    t.first
    t[1]
    t.last
  end

  x.report("Extend array") do
    t = A[:foo, "foo", 42]
    t.kind
    t.value
    t.start_index
  end

  x.report("Hash") do
    t = { foo: "bar", bar: "foo" }
    t[:foo]
    t[:bar]
  end

  x.report("Class") do
    t = T.new("foo", "bar")
    t.foo
    t.bar
  end

  x.report("Struct") do
    s = Token.new("foo", "bar")
    s.foo
    s.bar
  end

  x.report("Data") do
    t = D.new("bar", "foo")
    t.foo
    t.bar
  end

  x.report("New scanner") do
    StringScanner.new(+"foobar")
    StringScanner.new(+"barfoo")
  end

  x.report("Same scanner") do
    gss.string = +"foobar"
    gss.string = +"barfoo"
  end

  x.report("Scan bytes") do
    ss = StringScanner.new(+"foobar")
    ss.scan_byte
    ss.peek_byte
    ss.scan_byte
  end

  x.report("Scan regex") do
    ss = StringScanner.new(+"foobar")
    ss.scan(/[%\}]\}/)
  end
end
