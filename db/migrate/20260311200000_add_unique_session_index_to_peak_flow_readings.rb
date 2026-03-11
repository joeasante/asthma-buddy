class AddUniqueSessionIndexToPeakFlowReadings < ActiveRecord::Migration[8.1]
  def up
    # One morning and one evening reading per user per calendar day.
    # Uses a SQLite expression index on DATE(recorded_at) so the constraint
    # is enforced at the database level as a TOCTOU guard.
    execute <<~SQL
      CREATE UNIQUE INDEX index_peak_flow_readings_unique_session_per_day
      ON peak_flow_readings (user_id, time_of_day, DATE(recorded_at));
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_peak_flow_readings_unique_session_per_day;"
  end
end
