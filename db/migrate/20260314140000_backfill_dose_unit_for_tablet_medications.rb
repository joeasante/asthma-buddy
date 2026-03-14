# frozen_string_literal: true

class BackfillDoseUnitForTabletMedications < ActiveRecord::Migration[8.1]
  def up
    # medication_type 3 = other (includes steroids like Prednisolone), 4 = tablet
    execute <<~SQL
      UPDATE medications SET dose_unit = 'tablets'
      WHERE medication_type IN (3, 4) AND dose_unit = 'puffs'
    SQL
  end

  def down
    # No-op: cannot reliably determine original dose_unit
  end
end
