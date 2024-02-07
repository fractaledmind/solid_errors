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

Be sure to include this migration and schema change in the same release as the Solid Errors gem upgrade.
