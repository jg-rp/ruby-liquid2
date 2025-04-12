# frozen_string_literal: true

require "benchmark/ips"
require "json"
require "pathname"
require "liquid2"

# A benchmark fixture
class Fixture
  attr_reader :templates, :data

  def initialize(path)
    @root = Pathname.new(path)
    @name = @root.basename.to_s
    @data = JSON.parse((@root + "data.json").read)
    @templates = (@root + "templates").glob("*liquid").to_h { |p| [p.basename.to_s, p.read] }
  end

  def env
    Liquid2::Environment.new(loader: Liquid2::HashLoader.new(@templates), globals: @data)
  end
end

fixture = Fixture.new("test/cts/benchmark_fixtures/002")
env = fixture.env
source = fixture.templates["index.liquid"]
template = env.get_template("index.liquid")

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  x.report("scan template:") do
    Liquid2.tokenize(source)
  end

  x.report("scan and parse template:") do
    env.parse(source)
  end

  x.report("render template:") do
    template.render
  end

  x.report("parse and render template:") do
    env.parse(source).render
  end
end
