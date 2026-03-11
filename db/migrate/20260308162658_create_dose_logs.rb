# frozen_string_literal: true

class CreateDoseLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :dose_logs do |t|
      t.references :user,        null: false, foreign_key: true
      t.references :medication,  null: false, foreign_key: true
      t.integer    :puffs,       null: false
      t.datetime   :recorded_at, null: false
      t.timestamps
    end

    add_index :dose_logs, :recorded_at
    add_index :dose_logs, [ :medication_id, :recorded_at ]
  end
end
