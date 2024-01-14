# frozen_string_literal: true

class SolidErrors::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  class_option :skip_migrations, type: :boolean, default: nil, desc: "Skip migrations"

  def create_migrations
    unless options[:skip_migrations]
      rails_command "railties:install:migrations FROM=solid_errors", inline: true
    end
  end
end
