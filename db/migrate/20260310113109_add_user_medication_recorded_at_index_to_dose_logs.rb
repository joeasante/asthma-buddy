class AddUserMedicationRecordedAtIndexToDoseLogs < ActiveRecord::Migration[8.1]
  def change
    add_index :dose_logs, [ :user_id, :medication_id, :recorded_at ],
              name: "index_dose_logs_on_user_medication_recorded_at"
  end
end
