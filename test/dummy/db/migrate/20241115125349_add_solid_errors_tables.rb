class AddSolidErrorsTables < ActiveRecord::Migration[7.1]
  def change
    create_table "solid_errors", force: :cascade do |t|
      t.text "exception_class", null: false
      t.text "message", null: false
      t.text "severity", null: false
      t.text "source"
      t.datetime "resolved_at"
      t.string "fingerprint", limit: 64, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["fingerprint"], name: "index_solid_errors_on_fingerprint", unique: true
      t.index ["resolved_at"], name: "index_solid_errors_on_resolved_at"
    end

    create_table "solid_errors_occurrences", force: :cascade do |t|
      t.bigint "error_id", null: false
      t.text "backtrace"
      t.json "context"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["error_id"], name: "index_solid_errors_occurrences_on_error_id"
    end

    add_foreign_key "solid_errors_occurrences", "solid_errors", column: "error_id"
  end
end
