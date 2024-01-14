class CreateSolidErrorsTables < ActiveRecord::Migration[7.1]
  def change
    create_table :errors do |t|
      t.string :exception_class, null: false
      t.string :message, null: false
      t.string :severity, null: false
      t.string :source
      t.datetime :resolved_at, index: true

      t.timestamps

      t.index [:exception_class, :message, :severity, :source], unique: true
    end

    create_table :occurrences do |t|
      t.belongs_to :error, null: false, foreign_key: true
      t.text :backtrace
      t.json :context

      t.timestamps
    end
  end
end
