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
