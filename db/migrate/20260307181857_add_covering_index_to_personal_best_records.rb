class AddCoveringIndexToPersonalBestRecords < ActiveRecord::Migration[8.1]
  def change
    add_index :personal_best_records,
              [ :user_id, :recorded_at, :value ],
              name: "index_personal_best_records_covering"
  end
end
