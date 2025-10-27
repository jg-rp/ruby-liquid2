# Contributing to Ruby Liquid2

Your contributions and questions are always welcome. Feel free to ask questions, report bugs or request features on the [issue tracker](https://github.com/jg-rp/ruby-liquid2/issues) or on [Github Discussions](https://github.com/jg-rp/ruby-liquid2/discussions). Pull requests are welcome too.

## Development

The [Golden Liquid Test Suite](https://github.com/jg-rp/golden-liquid) is included in this repository as a Git [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules). Clone the Ruby Liquid2 repository and initialize the submodule with something like this:

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

Don't forget to benchmark with YJIT too:

```
bundle exec ruby --yjit performance/benchmark.rb
```

## Profiling

### CPU profile

Dump profile data with `bundle exec ruby performance/profile.rb`, then generate an HTML flame graphs with:

```
bundle exec stackprof --d3-flamegraph .stackprof-cpu-scan.dump > flamegraph-cpu-scan.html
bundle exec stackprof --d3-flamegraph .stackprof-cpu-parse.dump > flamegraph-cpu-parse.html
bundle exec stackprof --d3-flamegraph .stackprof-cpu-render.dump > flamegraph-cpu-render.html
```

### Memory profile

Print memory usage to the terminal.

```
bundle exec ruby performance/memory_profile.rb
```

Don't forget to inspect memory usage with YJIT enabled too.

```
bundle exec ruby --yjit performance/memory_profile.rb
```
