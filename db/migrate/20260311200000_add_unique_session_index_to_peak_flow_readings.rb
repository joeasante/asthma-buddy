# frozen_string_literal: true

# PRE-DEPLOY CHECK REQUIRED before running this migration in production:
# Run this SQL to confirm no duplicate sessions exist (migration will fail if any do):
#
#   SELECT user_id, time_of_day, DATE(recorded_at) AS reading_date, COUNT(*) AS cnt
#   FROM peak_flow_readings
#   GROUP BY user_id, time_of_day, DATE(recorded_at)
#   HAVING cnt > 1;
#
# Expected result: zero rows. If any rows are returned, deduplicate before deploying.

class AddUniqueSessionIndexToPeakFlowReadings < ActiveRecord::Migration[8.1]
  def up
    # One morning and one evening reading per user per calendar day.
    # Uses a SQLite expression index on DATE(recorded_at) so the constraint
    # is enforced at the database level as a TOCTOU guard.
    # NOTE: DATE(recorded_at) evaluates in UTC. The Rails-level validation in
    # one_session_per_day also uses UTC (Rails default timezone). If config.time_zone
    # is ever set to a non-UTC value, both this index and the Ruby validation must be
    # audited together — they will disagree about what "calendar day" means.
    execute <<~SQL
      CREATE UNIQUE INDEX index_peak_flow_readings_unique_session_per_day
      ON peak_flow_readings (user_id, time_of_day, DATE(recorded_at));
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_peak_flow_readings_unique_session_per_day;"
  end
end
