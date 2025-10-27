# frozen_string_literal: true

require "stackprof"
require "optparse"
require "pathname"
require "json"
require "liquid2"

# A benchmark fixture
class Fixture
  attr_reader :templates, :data

  # @param path [Pathname]
  def initialize(path)
    @root = path
    @name = @root.basename.to_s
    # rubocop:disable Style/StringConcatenation
    @data = JSON.parse((@root + "data.json").read)
    @templates = (@root + "templates").glob("*liquid").to_h { |p| [p.basename.to_s, p.read] }
    # rubocop:enable Style/StringConcatenation
  end

  def env
    Liquid2::Environment.new(loader: Liquid2::HashLoader.new(@templates), globals: @data)
  end
end

options = {
  fixture: "002"
}

OptionParser.new do |parser|
  parser.banner = <<~BANNER
    Run one of the benchmarks in ./tests/golden_liquid/benchmark_fixtures.
    Example: ruby benchmark.rb -f 002
  BANNER

  parser.on("-f FIXTURE", "--fixture FIXTURE",
            "The name of the benchmark fixture to run. Defaults to '002'.") do |value|
    options[:fixture] = value
  end

  parser.parse!
end

fixture = Fixture.new(Pathname.new("test/golden_liquid/benchmark_fixtures") + options[:fixture])
env = fixture.env
source = fixture.templates["index.liquid"]
template = env.get_template("index.liquid")

n = 1000

scanner = StringScanner.new("")

StackProf.run(mode: :cpu, raw: true, out: ".stackprof-cpu-scan.dump") do
  n.times do
    Liquid2::Scanner.tokenize(env, source, scanner)
  end
end

StackProf.run(mode: :cpu, raw: true, out: ".stackprof-cpu-parse.dump") do
  n.times do
    env.parse(source)
  end
end

StackProf.run(mode: :cpu, raw: true, out: ".stackprof-cpu-render.dump") do
  n.times do
    template.render
  end
end
