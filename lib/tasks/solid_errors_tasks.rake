namespace :solid_errors do
  desc "Copy and run migrations from Solid Errors"
  task install_migrations: :environment do
    source = File.expand_path("../../solid_errors/db/migrate", __FILE__)
    destination = File.join(Rails.root, "db", "migrate")

    Dir.glob("#{source}/*.rb").each do |migration|
      filename = File.basename(migration)
      unless File.exist?(File.join(destination, filename))
        puts "Copying #{filename} from Solid Errors to Rails application"
        FileUtils.cp(migration, destination)
      end
    end
    # this could be a way to "force" a migration to run in the future but
    # the more thought into this, it seems too rigid and hard-coded
    # Plus, after we copy the migration over, Rails will alert a user
    # to run migrations/there are pending migrations.
    # Set version for our specific migration
    # ENV["VERSION"] = "20240716154238"
    # Run just our specific migration file
    # Rake::Task["db:migrate:up"].invoke
    # Now clear that!
    # ENV["VERSION"] = nil
  end
end
