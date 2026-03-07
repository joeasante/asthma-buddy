class RemoveRedundantUserIdIndexFromPeakFlowReadings < ActiveRecord::Migration[8.1]
  # The composite (user_id, recorded_at) index covers all queries on user_id alone
  # via the leftmost-prefix rule. The single-column index is therefore redundant.
  def change
    remove_index :peak_flow_readings, name: "index_peak_flow_readings_on_user_id"
  end
end
