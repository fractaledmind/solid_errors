class AddPrevResolvedAtToSolidErrors < ActiveRecord::Migration[6.1]
  def change
    add_column :solid_errors, :prev_resolved_at, :timestamp
  end
end
