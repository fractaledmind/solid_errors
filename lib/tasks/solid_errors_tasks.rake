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

    puts "Running migrations from Solid Errors"
    Rake::Task["db:migrate"].invoke
  end
end
