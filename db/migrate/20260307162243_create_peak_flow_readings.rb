class CreatePeakFlowReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :peak_flow_readings do |t|
      t.integer :value, null: false
      t.datetime :recorded_at, null: false
      t.integer :zone
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :peak_flow_readings, [ :user_id, :recorded_at ]
  end
end
