require "benchmark/ips"
require "strscan"
require "stringio"

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

a = (1..1000).to_a

h = { "foo" => "bar", "bar" => "foo" }

ar = %w[foo bar]

ns = [
  { "foo" => "bar", "bar" => "foo" },
  { "foo" => "bar", "bar" => "foo" },
  { "foo" => "bar", "bar" => "foo", "baz" => false },
  { "foo" => "bar", "bar" => "foo" }
]

Benchmark.ips do |x|
  x.config(warmup: 2, time: 5)

  # x.report("Array") do
  #   t = [:foo, "foo"]
  #   t.first
  #   t[1]
  # end

  # x.report("Tuple") do
  #   t = [:foo, "foo", 42]
  #   t.first
  #   t[1]
  #   t.last
  # end

  # x.report("Extend array") do
  #   t = A[:foo, "foo", 42]
  #   t.kind
  #   t.value
  #   t.start_index
  # end

  # x.report("Hash") do
  #   t = { foo: "bar", bar: "foo" }
  #   t[:foo]
  #   t[:bar]
  # end

  # x.report("Class") do
  #   t = T.new("foo", "bar")
  #   t.foo
  #   t.bar
  # end

  # x.report("Struct") do
  #   s = Token.new("foo", "bar")
  #   s.foo
  #   s.bar
  # end

  # x.report("Data") do
  #   t = D.new("bar", "foo")
  #   t.foo
  #   t.bar
  # end

  # x.report("New scanner") do
  #   StringScanner.new(+"foobar")
  #   StringScanner.new(+"barfoo")
  # end

  # x.report("Same scanner") do
  #   gss.string = +"foobar"
  #   gss.string = +"barfoo"
  # end

  # x.report("Scan bytes") do
  #   ss = StringScanner.new(+"foobar")
  #   ss.scan_byte
  #   ss.peek_byte
  #   ss.scan_byte
  # end

  # x.report("Scan regex") do
  #   ss = StringScanner.new(+"foobar")
  #   ss.scan(/[%\}]\}/)
  # end

  # x.report("each") do
  #   a.each do |i|
  #     i + 1
  #   end
  # end

  # x.report("while index") do
  #   index = 0
  #   while (i = a[index])
  #     i + 1
  #     index += 1
  #   end
  # end

  # x.report("each index") do
  #   a.each_index do |index|
  #     i = a[index]
  #     i + 1
  #   end
  # end

  # x.report("StringIO") do
  #   s = StringIO.new("")
  #   s.write("foo")
  #   s.write("bar")
  #   s.string
  # end

  # x.report("String <<") do
  #   s = +""
  #   s << "foo"
  #   s << "bar"
  # end

  x.report("Fetch hash") do
    h.fetch("foo", :undefined)
    h.fetch("bar", :undefined)
    h.fetch("baz", :undefined)
  end

  x.report("Key? and [] (hash)") do
    h.key?("foo") ? h["foo"] : :undefined
    h.key?("bar") ? h["bar"] : :undefined
    h.key?("baz") ? h["baz"] : :undefined
  end

  x.report("Fetch array") do
    ar.fetch(0, :undefined)
    ar.fetch(1, :undefined)
    ar.fetch(2, :undefined)
  end

  x.report("Key? and [] (array)") do
    ar.length > 0 ? ar[0] : :undefined
    ar.length > 1 ? ar[1] : :undefined
    ar.length > 2 ? ar[2] : :undefined
  end

  x.report("rindex") do
    if (index = ns.rindex { |hs| hs.key?("baz") })
      ns[index]["baz"]
    end

    if (index = ns.rindex { |hs| hs.key?("banana") })
      ns[index]["banana"]
    end
  end

  x.report("while and return") do
    index = ns.length - 1
    while index >= 0
      hs = ns[index]
      if hs.key?("baz")
        hs["baz"]
        break
      end
      index -= 1
    end

    index = ns.length - 1
    while index >= 0
      hs = ns[index]
      if hs.key?("banana")
        hs["banana"]
        break
      end
      index -= 1
    end
  end
end
