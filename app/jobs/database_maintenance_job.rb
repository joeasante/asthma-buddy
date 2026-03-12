# frozen_string_literal: true

# Runs SQLite maintenance PRAGMAs across all configured databases.
# Scheduled daily via Solid Queue (config/recurring.yml).
#
# PRAGMA optimize: updates query planner statistics for tables/indices whose
# row counts have changed significantly since the last analysis. SQLite's query
# planner uses these statistics to choose the best index. Without periodic
# updates, it may silently choose a suboptimal scan plan as the dataset grows.
#
# PRAGMA wal_checkpoint(PASSIVE): merges committed WAL pages back into the main
# database file without blocking active readers or writers. This keeps the WAL
# file from growing unboundedly between the autocheckpoint thresholds and keeps
# read performance sharp (fewer WAL pages to scan on each read).
class DatabaseMaintenanceJob < ApplicationJob
  queue_as :default

  def perform
    db_paths.each do |path|
      SQLite3::Database.new(path) do |db|
        # analysis_limit caps the number of rows scanned per index during optimize,
        # keeping runtime predictable even on large tables. 400 is the SQLite-recommended
        # default for periodic maintenance; increases accuracy vs. a full ANALYZE.
        db.execute("PRAGMA analysis_limit=400;")
        db.execute("PRAGMA optimize;")
        db.execute("PRAGMA wal_checkpoint(PASSIVE);")
      end
      Rails.logger.info "[DatabaseMaintenance] Optimized #{File.basename(path)}"
    rescue => e
      Rails.logger.error "[DatabaseMaintenance] Failed on #{path}: #{e.message}"
    end
  end

  private

  def db_paths
    ActiveRecord::Base.configurations
      .configs_for(env_name: Rails.env)
      .filter_map(&:database)
      .select { |path| path.end_with?(".sqlite3") && File.exist?(path) }
  end
end
