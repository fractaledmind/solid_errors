# frozen_string_literal: true

require_relative "lib/solid_errors/version"

Gem::Specification.new do |spec|
  spec.name = "solid_errors"
  spec.version = SolidErrors::VERSION
  spec.authors = ["Stephen Margheim"]
  spec.email = ["stephen.margheim@gmail.com"]

  spec.summary = "Database-backed Rails error subscriber"
  spec.homepage = "https://github.com/fractaledmind/solid_errors"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fractaledmind/solid_errors"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  ">= 7.0".tap do |rails_version|
    spec.add_dependency "actionpack", rails_version
    spec.add_dependency "actionview", rails_version
    spec.add_dependency "activerecord", rails_version
    spec.add_dependency "activesupport", rails_version
    spec.add_dependency "railties", rails_version
  end

  spec.add_development_dependency "sqlite3"
end
