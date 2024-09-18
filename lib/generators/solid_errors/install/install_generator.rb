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

    def configure_solid_errors
      insert_into_file Pathname(destination_root).join("config/environments/production.rb"), after: /^([ \t]*).*?(?=\nend)$/ do
        [
          "",
          '\1# Configure Solid Errors',
          '\1config.solid_errors.connects_to = { database: { writing: :errors } }',
          '\1config.solid_errors.send_emails = true',
          '\1config.solid_errors.email_from = ""',
          '\1config.solid_errors.email_to = ""',
          '\1config.solid_errors.username = Rails.application.credentials.dig(:solid_errors, :username)',
          '\1config.solid_errors.password = Rails.application.credentials.dig(:solid_errors, :password)'
        ].join("\n")
      end
    end
  end
end
