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
