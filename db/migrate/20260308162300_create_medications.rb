class CreateMedications < ActiveRecord::Migration[8.1]
  def change
    create_table :medications do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,                  null: false
      t.integer :medication_type,       null: false           # enum: 0=reliever 1=preventer 2=combination 3=other
      t.integer :standard_dose_puffs,   null: false
      t.integer :starting_dose_count,   null: false
      t.integer :sick_day_dose_puffs                          # optional
      t.integer :doses_per_day                                # optional — required only when preventer has a schedule
      t.timestamps
    end
    add_index :medications, :medication_type
  end
end
