<h1 align="center">Ruby Liquid2</h1>

<p align="center">
Liquid templates for Ruby, with some extra features.
</p>

<p align="center">
  <a href="https://github.com/jg-rp/ruby-liquid2/blob/main/LICENSE.txt">
    <img alt="GitHub License" src="https://img.shields.io/github/license/jg-rp/ruby-liquid2?style=flat-square">
  </a>
  <a href="https://github.com/jg-rp/ruby-liquid2/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/jg-rp/ruby-liquid2/main.yml?branch=main&label=tests&style=flat-square" alt="Tests">
  </a>
  <br>
  <a href="https://rubygems.org/gems/liquid2">
    <img alt="Gem Version" src="https://img.shields.io/gem/v/liquid2?style=flat-square">
  </a>
  <a href="https://github.com/jg-rp/ruby-liquid2">
    <img alt="Static Badge" src="https://img.shields.io/badge/Ruby-3.1%20%7C%203.2%20%7C%203.3%20%7C%203.4-CC342D?style=flat-square">
  </a>
</p>

---

**Table of Contents**

- [Install](#install)
- [Example](#example)
- [Links](#links)
- [About](#about)
- [API](#api)
- [Development](#development)

## Install

Add `'liquid2'` to your Gemfile:

```
gem 'liquid2', '~> 0.3.0'
```

Or

```
gem install liquid2
```

Or

```
bundle add liquid2
```

## Example

```ruby
require "liquid2"

template = Liquid2.parse("Hello, {{ you }}!")
puts template.render("you" => "World")  # Hello, World!
puts template.render("you" => "Liquid")  # Hello, Liquid!
```

## Links

- Change log: https://github.com/jg-rp/ruby-liquid2/blob/main/CHANGELOG.md
- RubyGems: https://rubygems.org/gems/liquid2
- Source code: https://github.com/jg-rp/ruby-liquid2
- Issue tracker: https://github.com/jg-rp/ruby-liquid2/issues

## About

This project's template syntax aims to be mostly compatible with [Shopify/liquid](https://github.com/Shopify/liquid), but with fewer quirks and some new features. The [Ruby API](#api) is quite different.

For those already familiar with Liquid, here's a quick description of the features added in Liquid2. Also see [test/test_compliance.rb](https://github.com/jg-rp/ruby-liquid2/blob/main/test/test_compliance.rb) for a list of [golden tests](https://github.com/jg-rp/golden-liquid) that we skip.

### Additional features

#### "Proper" string literal parsing

String literals can contain markup delimiters (`{{`, `}}`, `{%`, `%}`, `{#` and `#}`) without interfering with template parsing, and c-like escape sequences. Escape sequences follow JSON string syntax and semantics, with the addition of single quoted strings and the `\'` escape sequence.

```liquid
{% assign x = "Hi \uD83D\uDE00!" %}
{{ x }}
```

**Output:**

```
Hi 😀!
```

#### String interpolation

String literals support interpolation using JavaScript-style `${` and `}`. Any single or double quoted string can use `${variable_name}` placeholders for automatic variable substitution, and `${` can be escaped with `\${` to prevent variable substitution.

Liquid template strings are effectively a shorthand alternative to `capture` tags or chains of `append` filters, which is especially useful when building short strings in `{% liquid %}` tags. These two tags are equivalent.

```liquid2
{% capture greeting %}
Hello, {{ you | capitalize }}!
{% endcapture %}

{% assign greeting = 'Hello, ${you | capitalize}!' %}
```

#### Array literals

Filtered expressions (those found in output statements, the `assign` tag and the `echo` tag) and `for` tag expressions support array literal syntax. We don't use the traditional `[item1, item2, ...]` syntax with square brackets because square brackets are already used for variables (`["some variable with spaces"]` is a valid variable).

```liquid2
{% assign my_array = a, b, '42', false -%}
{% for item in my_array -%}
    - {{ item }}
{% endfor %}
```

or, using a `{% liquid %}` tag:

```liquid2
{% liquid
    for item in a, b, '42', false
        echo "- ${item}\n"
    endfor %}
```

With `a` set to `"Hello"` and `b` set to `"World"`, both of the examples above produce the following output.

```plain title="output"
- Hello
- World
- 42
- false
```

#### Logical `not`

Logical expressions now support negation with the `not` operator and grouping terms with parentheses. Without parentheses, logical `and` takes priority over logical `or`.

In this example, `{% if not user %}` is equivalent to `{% unless user %}`, however, `not` can also be used after `and` and `or`, like `{% if user.active and not user.title %}`, potentially saving nested `if` and `unless` tags.

```liquid2
{% if not user %}
  please log in
{% else %}
  hello user
{% endif %}
```

#### Inline conditional and relational expressions

In most expressions where you'd normally provide a literal (string, integer, float, `true`, `false`, `nil`/`null`) or variable name/path (`foo.bar[0]`), you can now use an inline conditional or relational expression.

See [Shopify/liquid #1922](https://github.com/Shopify/liquid/pull/1922) and [jg-rp/liquid #175](https://github.com/jg-rp/liquid/pull/175).

These two templates are equivalent.

```liquid
{{ user.name or "guest" }}
```

```liquid
{% if user.name %}{{ user.name }}{% else %}guest{% endif %}
```

#### Ternary expressions

Output statements, the `{% assign %}` tag and the `{% echo %}` tag support ternary expressions.

```liquid2
{{ a if b else c }}
{{ a | upcase if b == 'foo' else c || split }}
```

Either branch can use filters with the usual single pipe character (`|`), like `upcase` in the examples above. Filters following a double pipe (`||`) are _tail filters_, which apply to both branches.

#### Lambda expressions

Many built-in filters that operate on arrays now accept lambda expression arguments. For example, we can use the `where` filter to select values according to an arbitrary Boolean expression.

```liquid2
{% assign coding_pages = pages | where: page => page.tags contains 'coding' %}
```

#### Dedicated comment syntax

Text surrounded by `{#` and `#}` are comments. Additional `#`'s can be added to comment out blocks of markup that already contain comments, as long as hashes are balanced.

```liquid2
{## comment this out for now
{% for x in y %}
    {# x could be empty #}
    {{ x | default: TODO}}
{% endfor %}
##}
```

#### More whitespace control

Tags and the output statement support `-` and `~` for controlling whitespace in templates. By default, `~` will remove newlines but retain space and tab characters.

Here we use `~` to remove the newline after the opening `for` tag, but preserve indentation before `<li>`.

```liquid2
<ul>
{% for x in (1..4) ~%}
  <li>{{ x }}</li>
{% endfor -%}
</ul>
```

```plain title="output"
<ul>
  <li>1</li>
  <li>2</li>
  <li>3</li>
  <li>4</li>
</ul>
```

#### Arithmetic operators

Arithmetic infix operators `+`, `-`, `*`, `/`, `%` and `**`, and prefix operators `+` and `-`, are an experimental feature and are disabled by default. Enable them by passing `arithmetic_operators: true` to a new [`Liquid2::Environment`](https://github.com/jg-rp/ruby-liquid2/blob/main/lib/liquid2/environment.rb).

#### Scientific notation

Integer and float literals can use scientific notation, like `1.2e3` or `1e-2`.

#### Extra tags and filters

Liquid2 includes implementations of `{% extends %}` and `{% block %}` for template inheritance, `{% with %}` for block scoped variables and `{% macro %}` and `{% call %}` for defining parameterized blocks.

The following filters are included in Liquid2's default environment:

- `sort_numeric` - Sorts array elements by runs of digits found in their string representation.
- `json` - Outputs objects serialized in JSON format.
- `range`- An alternative to the standard `slice` filter that takes optional start and stop indexes, and an optional step, all of which can be negative.

See [Tags and filters](#tags-and-filters) for how to add, remove or alias tags and/or filters from your own Liquid2 environment.

## API

### Liquid2.render

`self.render: (String source, ?Hash[String, untyped]? data) -> String`

Parse and render Liquid template _source_ using the default Liquid environment. If _data_ is given, hash keys will be available as template variables with their associated values.

```ruby
require "liquid2"

puts Liquid2.render("Hello, {{ you }}!", "you" => "World")  # Hello, World!
```

This is a convenience method equivalent to `Liquid2::DEFAULT_ENVIRONMENT.parse(source).render(data)`.

### Liquid2.parse

`self.parse: (String source, ?globals: Hash[String, untyped]?) -> Template`

Parse or "compile" Liquid template _source_ using the default Liquid environment. The resulting `Liquid2::Template` instance has a `render(data)` method, which can be called multiple times with different data.

```ruby
require "liquid2"

template = Liquid2.parse("Hello, {{ you }}!")
puts template.render("you" => "World") # Hello, World!
puts template.render("you" => "Liquid") # Hello, Liquid!
```

If the _globals_ keyword argument is given, that data will be _pinned_ to the template and will be available as template variables every time you call `Template#render`. Pinned data will be merged with data passed to `Template#render`, with `render` arguments taking priority over pinned data if there's a name conflict.

`Liquid2.render(source)` is a convenience method equivalent to `Liquid2::DEFAULT_ENVIRONMENT.parse(source)` or `Liquid2::Environment.new.parse(source)`.

### Configure

Both `Liquid2.parse` and `Liquid2.render` are convenience methods that use the default `Liquid2::Environment`. Often you'll want to configure an environment, then load and render template from that.

```ruby
require "liquid2"

env = Liquid2::Environment.new(loader: Liquid2::CachingFileSystemLoader.new("templates/"))
template = env.parse("Hello, {{ you }}!")
template.render("you" => "World") # Hello, World!
```

Assuming you've configured a template loader, `Environment#get_template(name)`, the `{% render %}` tag and the `{% include %}` tag will use that `Liquid2::Loader` to find, read and parse templates. This example will look for templates in a relative folder on your file system called `templates`.

```ruby
require "liquid2"

env = Liquid2::Environment.new(loader: Liquid2::CachingFileSystemLoader.new("templates/"))
template = env.get_template("index.liquid")
another_template = env.parse("{% render 'index.liquid' %}")
# ...
```

We'd expect a `Liquid2::LiquidTemplateNotFoundError` if `index.liquid` does not exist in the folder `templates/`.

See [`environment.rb`](https://github.com/jg-rp/ruby-liquid2/blob/main/lib/liquid2/environment.rb) for all `Liquid2::Environment` options. Builtin template loaders are [`HashLoader`](https://github.com/jg-rp/ruby-liquid2/blob/main/lib/liquid2/loader.rb), [`FileSystemLoader`](https://github.com/jg-rp/ruby-liquid2/blob/main/lib/liquid2/loaders/file_system_loader.rb) and `CachingFileSystemLoader`. You are encouraged to implement your own template loaders to read template source text from a database or parse front matter, for example.

#### Tags and filters

All builtin tags and filters are registered with a new `Liquid2::Environment` by default. You can register or remove tags and/or filters using `Environment#register_filter`, `Environment#delete_filter`, `Environment#register_tag` and `Environment#delete_tag`, or override `Environment#setup_tags_and_filters` in an `Environment` subclass.

```ruby
require "liquid2"

class MyEnv < Liquid2::Environment
  def setup_tags_and_filters
    super
    delete_filter("base64_decode")
    delete_filter("base64_encode")
    delete_filter("base64_url_safe_decode")
    delete_filter("base64_url_safe_encode")
    register_tag("with", WithTag)
  end
end

env = MyEnvironment.new
# ...
```

See [`environment.rb`](https://github.com/jg-rp/ruby-liquid2/blob/main/lib/liquid2/environment.rb) for a list of builtin tags and filters, [`lib/liquid2/filters`](https://github.com/jg-rp/ruby-liquid2/tree/main/lib/liquid2/filters) for example filter implementations, and [`lib/liquid/nodes/tags`](https://github.com/jg-rp/ruby-liquid2/tree/main/lib/liquid2/nodes/tags) for example tag implementations.

#### Undefined

The default _undefined_ type is an instance of `Liquid2::Undefined`. It is silently ignored and, when rendered, produces an empty string. Passing `undefined: Liquid2::StrictUndefined` when initializing a `Liquid2::Environment` will cause all uses of an undefined template variable to raise a `Liquid2::UndefinedError`.

```ruby
require "liquid2"

env = Liquid2::Environment.new(undefined: Liquid2::StrictUndefined)
template = env.parse("Hello, {{ nosuchthing }}!")
puts template.render
#   -> "Hello, {{ nosuchthing }}!":1:10
#   |
# 1 | Hello, {{ nosuchthing }}!
#   |           ^^^^^^^^^^^ "nosuchthing" is undefined
```

By default, instances of `Liquid2::StrictUndefined` are considered falsy when tested for truthiness, without raising an error.

```ruby
require "liquid2"

env = Liquid2::Environment.new(undefined: Liquid2::StrictUndefined)
template = env.parse("Hello, {{ nosuchthing or 'foo' }}!")
puts template.render # Hello, foo!
```

Setting `falsy_undefined: false` when initializing a `Liquid2::Environment` will cause instances of `Liquid2::StrictUndefined` to raise an error when tested for truthiness.

There's also `Liquid2::StrictDefaultUndefined`, which behaves like `StrictUndefined` but plays nicely with the `default` filter.

### Static analysis

Instances of `Liquid2::Template` include several methods for statically analyzing the template's syntax tree and reporting tag, filter and variable usage.

`Template#variables` returns an array of variables used in the template. Notice that we get the _root segment_ only, excluding segments that make up a path to a variable.

```ruby
require "liquid2"

source = <<~LIQUID
  Hello, {{ you }}!
  {% assign x = 'foo' | upcase %}

  {% for ch in x %}
      - {{ ch }}
  {% endfor %}

  Goodbye, {{ you.first_name | capitalize }} {{ you.last_name }}
  Goodbye, {{ you.first_name }} {{ you.last_name }}
LIQUID

template = Liquid2.parse(source)
p template.variables # ["you", "x", "ch"]
```

`Template#variable_paths` is similar, but includes all segments for each variable/path.

```ruby
# ... continued from above
p template.variable_paths # ["you", "you.first_name", "you.last_name", "x", "ch"]
```

And `Template#variable_segments` does the same, but returns each variable/path as an array of segments instead of a string.

```ruby
# ... continued from above
p template.variable_segments # [["you"], ["you", "first_name"], ["you", "last_name"], ["x"], ["ch"]]
```

Sometimes you'll only be interested in variables that are not in scope from previous tags (like `assign` and `capture`) or temporary block scope variables (like `forloop`). We call such variables "global" and provide `Template#global_variables`, `Template#global_variable_paths` and `Template#global_variable_segments`.

```ruby
# ... continued from above
p template.global_variables # ["you"]
```

`Template#tag_names` and `Template#filter_names` return an array of tag and filter names used in the template.

```ruby
# ... continued from above
p template.filter_names # ["upcase", "capitalize"]
p template.tag_names # ["assign", "for"]
```

`Template#macros` returns arrays of `{% macro %}` and `{% call %}` tags found in the template.

```ruby
require "liquid2"

source = <<~LIQUID
  {% macro foo, you %}Hello, {{ you }}!{% endmacro -%}
  {% call foo, 'World' %}
  {% call bar, 'Liquid' %}
LIQUID

template = Liquid2.parse(source)
macro_tags, call_tags = template.macros

p macro_tags.map(&:macro_name).uniq # ["foo"]
p call_tags.map(&:macro_name).uniq # ["foo", "bar"]
```

Finally there's `Template#comments` and `Template#docs`, which return instances of comments nodes and `DocTag` nodes, respectively. Each node has a `token` attribute, including a start index, and a `text` attribute, which is the comment or doc text.

```ruby
require "liquid2"

source = <<~LIQUID
  {% doc %}
    Some doc comment
  {% enddoc %}
  {% assign x = 42 %}

  {# note y could be nil #}
  {{ x | plus: y or 7 }}
LIQUID

template = Liquid2.parse(source)
p template.docs.map(&:text) # ["\n  Some doc comment\n"]
p template.comments.map(&:text) # [" note y could be nil "]
```

### Drops

Our "drop" interface defines the methods used by Liquid2 when non-primitive values appear as variables in templates. Primitive types are strings, integers, floats, `true`, `false`, `nil`/`null`, hashes, arrays and the special `blank` and `empty` objects. All other objects are accessed using the drop interface.

#### To string

`to_s` is called when outputting a drop.

```ruby
require "liquid2"

class MyDrop
  def to_s
    "Hi!"
  end
end

puts Liquid2.render("{{ thing }}", "thing" => MyDrop.new) # Hi!
```

#### Item fetching and method calling

We use `[](key)` and `key?(key)` both for fetching items from a collection-like object and/or calling methods. Notice that `baz` is not called in this example.

```ruby
require "liquid2"

class MyDrop
  INVOCABLE = Set["foo", "bar"]

  def [](key)
    send(key) if INVOCABLE.member?(key)
  end

  def key?(key)
    INVOCABLE.member?(key)
  end

  def foo = 42
  def bar = "Hello!"
  def baz = "not public"
end

puts Liquid2.render("{{ thing.foo }} {{ thing.baz }}", "thing" => MyDrop.new) # 42
```

#### Enumerating drops

Any `Enumerable` will work with the `{% for %}` tag and filters that operate on arrays.

```ruby
require "liquid2"

class MyDrop
  include Enumerable

  def each
    yield "foo"
    yield "bar"
    yield 42
  end
end

puts Liquid2.render("{% for x in y %}{{ x }},{% endfor %}", "y" => MyDrop.new) # foo,bar,42,
```

#### First, last and size

If an object responds to `first`, `last` or `size`, those methods will be called by the `first`, `last` and `size` filters, and the special `.first`, `.last` or `.size` attributes.

```ruby
require "liquid2"

class MyDrop
  def first
    42
  end
end

puts Liquid2.render("{{ x.first }} {{ x | first }}", "x" => MyDrop.new) # 42 42
```

#### Lazy slicing

If an object responds to `slice`, Liquid will call it with `start`, `length` and `reversed` arguments when evaluating it as a `for` loop target. `slice` takes priority over `is_a?(Enumerable)` and is intended for lazily loading items when slicing large collections.

```ruby
require "liquid2"

class MyDrop
  def initialize(*items)
    @items = items
  end

  def slice(start, length, reversed)
    # Pretend items are coming from a database or over a network.
    array = @items.slice(start || 0, length || @items.length)
    reversed ? array.reverse! : array
  end
end

puts Liquid2.render("{% for x in y offset: 2, limit: 5 %}{{ x }},{% endfor %}", "y" => MyDrop.new) # 2,3,4,5,6,
```

#### Truthiness, comparisons and path segments

If an object responds to `to_liquid(context)`, `to_liquid` will be called and the result used when testing drops for truthiness, comparing a drop to another value or when using the drop as a variable path segment.

```ruby
require "liquid2"

class MyDrop
  # @param context [RenderContext]
  def to_liquid(_context)
    "foo"
  end
end

puts Liquid2.render("{% if x == 'foo' %}true{% else %}false{% endif %}", "x" => MyDrop.new) # true
```

## Development

The [golden liquid](https://github.com/jg-rp/golden-liquid) test suite is included in this repository as a Git [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules). Clone this project and initialize the submodule with something like:

```shell
$ git clone git@github.com:jg-rp/ruby-liquid2.git
$ cd ruby-liquid2
$ git submodule update --init
```

We use [Bundler](https://bundler.io/) and [Rake](https://ruby.github.io/rake/). Install development dependencies with:

```
bundle install
```

Run tests with:

```
bundle exec rake test
```

Lint with:

```
bundle exec rubocop
```

And type check with:

```
bundle exec steep
```

Run one of the benchmarks with:

```
bundle exec ruby performance/benchmark.rb
```

### Profiling

#### CPU profile

Dump profile data with `bundle exec ruby performance/profile.rb`, then generate an HTML flame graph with, changing the file names appropriately:

```
bundle exec stackprof --d3-flamegraph .stackprof-cpu-parse.dump > flamegraph-cpu-parse.html
```

#### Memory profile

Print memory usage to the terminal.

```
bundle exec ruby performance/memory_profile.rb
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

This project is not affiliated with Shopify, but we do reference [Shopify/liquid](https://github.com/Shopify/liquid) frequently and have used code from Shopify/liquid. See `LICENSE_SHOPIFY.txt` for a copy of the Shopify/liquid license.
