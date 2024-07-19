namespace :solid_errors do
  desc "Copy and run migrations from Solid Errors"
  task install_migrations: :environment do
    source = File.expand_path("../../solid_errors/db/migrate", __FILE__)
    destination = Rails.root.join('db', 'migrate')

    Dir.children(source).each do |migration|
      timestamp = Time.now.strftime('%Y%m%d%H%M%S_')
      filename_with_timestamp = "#{timestamp}_#{migration}"

      if Dir.glob("#{destination}/*#{original_filename}").empty?
        puts "Copying #{migration} to #{filename_with_timestamp} from Solid Errors to Rails application"
        FileUtils.cp(migration, File.join(destination, filename_with_timestamp))
      end
    end
  end
end
