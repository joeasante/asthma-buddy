class AddDoseUnitToMedications < ActiveRecord::Migration[8.1]
  def change
    add_column :medications, :dose_unit, :string, default: "puffs", null: false
  end
end
