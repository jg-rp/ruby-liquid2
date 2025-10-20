# Arrays in Liquid2

TODO: introduction

## Immutable data guarantee

Liquid2, in its default configuration, will never mutate render context data. This behavior ensures that rendering the same template with the same inputs always yields identical results, and that data passed into the template cannot be changed accidentally or maliciously.

Some Liquid2 deployments may choose to support controlled data mutation for performance or integration reasons. In those configurations, custom filters and tags may mutate existing data structures. However, the default runtime always treats data as immutable, providing deterministic and side-effect-free rendering suitable for static publishing, caching, and sandboxed execution.

As such, there are no built-in `append`, `add`, `prepend` or `removed` filters for mutating arrays, nor filters for adding, removing or setting keys in objects/hashes.

## Literals

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

The spread operator `...` allows authors to compose arrays immutably from existing arrays and enumerables.

```liquid
{% assign x = [1, 2, 3] %}
{% assign y = [...x, "a"] %}
{{ y | json }}
```

**Output**

```json
[1, 2, 3, "a"]
```

TODO: object/hash literals
