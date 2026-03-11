class CreateSymptomLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :symptom_logs do |t|
      t.integer :symptom_type, null: false
      t.integer :severity, null: false
      t.datetime :recorded_at, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :symptom_logs, [ :user_id, :recorded_at ]
  end
end
