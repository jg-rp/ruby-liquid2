# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new do |task|
  task.plugins << "rubocop-minitest"
  task.plugins << "rubocop-rake"
  task.plugins << "rubocop-performance"
end

require "steep/rake_task"

Steep::RakeTask.new do |t|
  t.check.severity_level = :error
  t.watch.verbose
end

task default: %i[test rubocop steep]
