# Solid Errors Upgrade Guide

Follow this guide to upgrade your Solid Errors implementation to the next version

## Solid Errors 0.4.0

We've added a `fingerprint` column to the `solid_errors` table and changed the `exception_class`, `message`, `severity`, and `source` columns to be limitless `text` type columns. This allows the unique index on the table to be on the single `fingerprint` column, which is a SHA256 hash of the `exception_class`, `message`, `severity`, and `source` columns. This change resolves problems with the unique index being too large as well as problems with one of the data columns being truncated. But, it requires a migration to update the `solid_errors` table.

Create a migration for whatever database stores your errors:
```bash
rails generate migration UpgradeSolidErrors --database {name_of_errors_database}
```

Then, update the migration file with the following code:
```ruby
class UpgradeSolidErrors < ActiveRecord::Migration[7.1]
  def up
    change_column :solid_errors, :exception_class, :text, null: false, limit: nil
    change_column :solid_errors, :message, :text, null: false, limit: nil
    change_column :solid_errors, :severity, :text, null: false, limit: nil
    change_column :solid_errors, :source, :text, null: true, limit: nil
    add_column :solid_errors, :fingerprint, :string, limit: 64
    add_index :solid_errors, :fingerprint, unique: true
    remove_index :solid_errors, [:exception_class, :message, :severity, :source], unique: true
  end

  def down
    change_column :solid_errors, :exception_class, :string, null: false, limit: 200
    change_column :solid_errors, :message, :string, null: false, limit: nil
    change_column :solid_errors, :severity, :string, null: false, limit: 25
    change_column :solid_errors, :source, :string, null: true, limit: nil
    remove_index :solid_errors, [:fingerprint], unique: true
    remove_column :solid_errors, :fingerprint, :string, limit: 64
    add_index :solid_errors, [:exception_class, :message, :severity, :source], unique: true
  end
end
```

Then, run this migration:
```bash
rails db:migrate:{name_of_errors_database}
```

Once the migration is complete, you will next need to fingerprint any existing errors in your database. This can be done using the following Ruby script, which can be put in a Rake task, a data migration, or simply done in the console:
```ruby
SolidErrors::Error.where(fingerprint: nil).find_each do |error|
  error_attributes = error.attributes.slice('exception_class', 'message', 'severity', 'source')
  fingerprint = Digest::SHA256.hexdigest(error_attributes.values.join)
  error.update_attribute(:fingerprint, fingerprint)
end
```

You will need to run this script _as soon as the schema migration_ is complete so that you can fingerprint all existing errors before new errors with pre-generated fingerprints are recorded.

Once you have migrated all existing errors to include a fingerprint, the final step is to run one more schema migration to mark the `fingerprint` column as non-nullable. You can generate a migration for this with the following command:
```bash
rails generate migration SolidErrorFingerprintNonNullable --database {name_of_errors_database}
```

Then, update the migration file with the following code:
```ruby
class SolidErrorFingerprintNonNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :solid_errors, :fingerprint, false
  end
end
```

Once this migration has been successfully run in production, your upgrade to Solid Errors 0.4.0 is complete!
