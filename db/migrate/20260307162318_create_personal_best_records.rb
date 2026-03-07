class CreatePersonalBestRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_best_records do |t|
      t.integer :value, null: false
      t.datetime :recorded_at, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :personal_best_records, [ :user_id, :recorded_at ]
  end
end
