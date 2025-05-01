<h1 align="center">Ruby Liquid2</h1>

<p align="center">
Liquid templates for Ruby, with some extra features.
</p>

---

**Table of Contents**

- [Install](#install)
- [Example](#example)
- [Links](#links)
- [About](#about)
- [Usage](#usage)

## Install

TODO

## Example

```ruby
require "liquid2"

template = Liquid2.parse("Hello, {{ you }}!")
puts template.render("you" => "World")  # Hello, World!
puts template.render("you" => "Liquid")  # Hello, Liquid!
```

## Links

- Change log: https://github.com/jg-rp/ruby-liquid2/blob/main/CHANGELOG.md
- RubyGems: TODO
- Source code: https://github.com/jg-rp/ruby-liquid2
- Issue tracker: https://github.com/jg-rp/ruby-liquid2/issues

## About

This project aims to be mostly compatible with [Shopify/liquid](https://github.com/Shopify/liquid), but with fewer quirks and some new features.

For those already familiar with Liquid, here's a quick description of the features added in Liquid2. Also see [test/test_compliance.rb](https://github.com/jg-rp/ruby-liquid2/blob/main/test/test_compliance.rb) for a list of [golden tests](https://github.com/jg-rp/golden-liquid) that we skip.

### Additional features

#### "Proper" string literal parsing

String literals can contain markup delimiters (`{{`, `}}`, `{%`, `%}`, `{#` and `#}`) and c-like escape sequences without interfering with template parsing. Escape sequences follow JSON string syntax and semantics, with the addition of single quoted strings and the `\'` escape sequence.

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

In most expressions where you'd normally provide a literal (string, integer, float, true, false, nil/null) or variable name/path (foo.bar[0]), you can now use an inline conditional or relational expression.

See [Shopify/liquid #1922](https://github.com/Shopify/liquid/pull/1922) and [jg-rp/liquid #175](https://github.com/jg-rp/liquid/pull/175).

These two templates are equivalent.

```liquid
{{ user.name || "guest" }}
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

Comments surrounded by `{#` and `#}` are enabled by default. Additional `#`'s can be added to comment out blocks of markup that already contain comments, as long as hashes are balanced.

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

#### Scientific notation

Integer and float literals can use scientific notation, like `1.2e3` or `1e-2`.

## Usage

TODO

## Development

TODO

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

### Profiling

#### CPU profile

Dump profile data with `bundle exec ruby performance/profile.rb`, then generate an HTML flame graph with, changing the file names appropriately:

```
bundle exec stackprof --d3-flamegraph .stackprof-cpu-parse.dump > flamegraph-cpu-parse.html
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

This project is not affiliated with Shopify, but we do reference [Shopify/liquid](https://github.com/Shopify/liquid) frequently and have used code from Shopify/liquid. See `LICENSE_SHOPIFY.txt` for a copy of the Shopify/liquid license.
