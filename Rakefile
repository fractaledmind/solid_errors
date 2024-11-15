# frozen_string_literal: true

require "bundler/setup"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
# load "rails/tasks/engine.rake"
# load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"
require "rake/testtask"
require "standard/rake"

task default: %i[test standard]

Rake::TestTask.new(:test) do |t|
  sh("TARGET_DB=sqlite bin/setup")
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end
