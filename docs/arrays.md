# Arrays in Liquid2

TODO: introduction

## Immutable data guarantee

TODO: Why we don't include filters and/or tags to modify data.

## Literals

```liquid
{{ [1, 2, 3] }}
{{ ['a', 'b', 'c'] }}

{% assign some_array = [x, y, z] %}

{% for x in [1, 2, 3] %}
  - {{ x }}
{% endfor %}
```

Square brackets are optional in the left-hand side of a filtered expression or a for loop target, as long as there's at least two items.

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

TODO: spread operator

TODO: object/hash literals
