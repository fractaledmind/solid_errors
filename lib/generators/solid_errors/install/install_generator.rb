# frozen_string_literal: true

module SolidErrors
  #
  # Rails generator used for setting up SolidErrors in a Rails application.
  # Run it with +bin/rails g solid_errors:install+ in your console.
  #
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def add_solid_errors_db_schema
      template "db/errors_schema.rb"
    end
  end
end
