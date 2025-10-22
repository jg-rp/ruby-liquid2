## [0.5.0] - 25-22-10

- Improved array literal syntax. Arrays with square brackets are now allowed anywhere a value (literal or variable) is expected. See [#21](https://github.com/jg-rp/ruby-liquid2/issues/21) and `docs/composite_literals.md`.
- Added object (aka hash) literal syntax. Like arrays, object literals are allowed anywhere a value (literal or variable) is expected. See `docs/composite_literals.md`.
- Added the spread operator `...`. Like spread syntax in JavaScript, the spread operator is used to expand array elements inside array literals and merge objects (aka hashes) in object literals. See `docs/composite_literals.md`.
- Improved `{% cycle %}` tag implementation. We no longer evaluate all items for every call to `CycleTag#render`, just the next item in the cycle. We also cache cycle context keys if the key is known at parse time.

## [0.4.0] - 25-08-11

- Fixed a bug where the parser would raise a `Liquid2::LiquidSyntaxError` if environment arguments `markup_out_end` and `markup_tag_end` where identical. See [#23](https://github.com/jg-rp/ruby-liquid2/issues/23).
- Added `Liquid2::Environment.persistent_namespaces`. It is an array of symbols indicating which namespaces from `Liquid2::RenderContext.tag_namespaces` should be preserved when calling `Liquid2::RenderContext#copy`. This is important for some tags - like `{% extends %}` - that need to share state with partial templates rendered with `{% render %}`.
- Added the `auto_trim` argument to `Liquid2::Environment`. `auto_trim` can be `'-'`, `'~'` or `nil` (the default). When not `nil`, it sets the automatic whitespace trimming applied to the left side of template text when no explicit whitespace control is given. `+` is also available as whitespace control in tags, outputs statements and comments. A `+` will ensure no trimming is applied, even if `auto_trim` is set.

## [0.3.1] - 25-06-24

- Added support for custom markup delimiters. See [#16](https://github.com/jg-rp/ruby-liquid2/pull/16).
- Added the `range` filter. `range` is an array slicing filter that takes optional start and end indexes, and an optional step argument, any of which can be negative. See [#18](https://github.com/jg-rp/ruby-liquid2/pull/18).

## [0.3.0] - 25-05-29

- Fixed static analysis of lambda expressions (arrow functions). Previously we were not including lambda parameters in the scope of the expression. See [#12](https://github.com/jg-rp/ruby-liquid2/issues/12).
- Fixed parsing of variable paths that start with `true`, `false`, `nil` or `null`. For example, `{{ true.foo }}`. See [#13](https://github.com/jg-rp/ruby-liquid2/issues/13).
- Added support for arithmetic infix operators `+`, `-`, `*`, `/`, `%` and `**`, and prefix operators `+` and `-`. These operators are disabled by default. Enable them by passing `arithmetic_operators: true` to a new `Liquid2::Environment`.

## [0.2.0] - 25-05-12

- Fixed error context info when raising `UndefinedError` from `StrictUndefined`.
- Fixed parsing of compound expressions given as filter arguments.
- Fixed sorting of string representations of floats with the `sort_numeric` filter.
- Fixed the string representation of variable paths with bracket notation and nested paths.
- Added `Template#docs`, which returns an array of `DocTag` instances used in a template.
- Added implementations of the `{% macro %}` and `{% call %}` tags.
- Added `Template#macros`, which returns arrays of `{% macro %}` and `{% call %}` tags used in a template.
- Added template inheritance tags `{% extends %}` and `{% block %}`.
- Added block scoped variables with the `{% with %}` tag.

## [0.1.1] - 2025-05-01

- Add `base64` dependency to gemspec.

## [0.1.0] - 2025-05-01

- Initial release
