# Composite literals in Liquid2

Liquid2, in its default configuration, will never mutate render context data. This behavior ensures that rendering the same template with the same inputs always yields identical results, and that data passed into the template cannot be changed accidentally or maliciously.

Some Liquid2 deployments may choose to support controlled data mutation for performance or integration reasons. In those configurations, custom filters and tags may mutate existing data structures. However, the default runtime always treats data as immutable, providing deterministic and side-effect-free rendering suitable for static publishing, caching, and sandboxed execution.

As such, there are no built-in `append`, `add`, `prepend` or `removed` filters for mutating arrays, nor filters for adding, removing or setting keys in objects (aka hashes or mappings). Instead, we introduce **array and object literals**, and the spread operator `...`.

## Array literals

```liquid
{{ [1, 2, 3] }}
{{ ['a', 'b', 'c'] }}

{% assign some_array = [x, y, z] %}

{% for x in [1, 2, 3] %}
  - {{ x }}
{% endfor %}
```

Square brackets are optional on the left-hand side of a filtered expression or a for loop target, as long as there's at least two items.

```liquid
{{ 1, 2, 3 | join: '-' }}

{% for x in 1, 2, 3 %}
  - {{ x }}
{% endfor %}
```

Empty arrays are OK. Single element arrays must include a trailing comma to differentiate them from bracketed variable/path notation.

```liquid
{% assign empty_array = [] %}
{% assign some_array = [x,] %}
```

Array literals can be arbitrarily nested.

```liquid
{% liquid
  assign things = [["foo", 1], ["bar", 2]]
  for item in things
      echo "${item[0]}: ${item[1]}\\n"
  endfor
%}
```

The standard `concat` filter can accept an array literal as its argument. It always returns a new array.

```liquid
{% assign default_colors = "red", "blue" %}
{% assign all_colors = default_colors | concat: ["green",] %}
```

You can also map to arrays using the `map` filter and an arrow function argument.

**Data**

```json
{
  "pages": [
    { "dir": "foo", "url": "example.com", "filename": "file1" },
    { "dir": "bar", "url": "thing.com", "filename": "file2" }
  ]
}
```

```liquid
{% assign downloads = pages | map: p => [p.filename, "${p.url}/${p.dir}"] %}
{% for item in downloads %}
  {{ item | join: ": " }}
{% endfor %}
```

The spread operator `...` allows template authors to compose arrays immutably from existing arrays and enumerables.

```liquid
{% assign x = [1, 2, 3] %}
{% assign y = [...x, "a"] %}
{{ y | json }}
```

**Output**

```json
[1, 2, 3, "a"]
```

## Object literals

Object literals (also known as hashes or mappings) define key–value pairs enclosed in curly braces `{}`. Keys must be static identifiers or string literals, and braces are always required.

```liquid
{% assign point = {x: 10, y: 20} %}
{{ point.x }}

{{ {"foo": "bar", "baz": 42} | json }}
```

Object literals can contain values of any type, including arrays, objects, and interpolated strings.

```liquid
{% assign profile = {
    name: "Ada",
    age: 42,
    tags: ["engineer", "mathematician"]
  } %}

{{ profile.name }}
```

Keys may be written as unquoted identifiers or quoted strings. Both forms are equivalent:

```liquid
{% assign a = {foo: 1, "bar": 2} %}
```

The spread operator `...` can also be used within object literals to merge key–value pairs from other objects or expressions. Each spread is evaluated in order, and later keys override earlier ones. The source objects themselves are never mutated.

```liquid
{% assign defaults = {a: 1, b: 2} %}
{% assign overrides = {b: 9, c: 3} %}
{% assign merged = {...defaults, ...overrides, d: 4} %}
{{ merged | json }}
```

**Output**

```json
{ "a": 1, "b": 9, "c": 3, "d": 4 }
```

Spread values are evaluated as follows:

- **Hashes (objects)** are merged directly.
- **Objects responding to `to_h`** are converted and merged.
- **Other values** are ignored (treated as empty objects).
