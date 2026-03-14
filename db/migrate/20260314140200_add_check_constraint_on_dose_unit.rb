# frozen_string_literal: true

class AddCheckConstraintOnDoseUnit < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :medications, "dose_unit IN ('puffs', 'tablets', 'ml')", name: "medications_dose_unit_check"
  end
end
