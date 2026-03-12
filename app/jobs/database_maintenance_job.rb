# frozen_string_literal: true

# Runs SQLite maintenance PRAGMAs across all configured databases.
# Scheduled daily via Solid Queue (config/recurring.yml).
#
# PRAGMA optimize: updates query planner statistics for tables/indices whose
# row counts have changed significantly since the last analysis. SQLite's query
# planner uses these statistics to choose the best index. Without periodic
# updates, it may silently choose a suboptimal scan plan as the dataset grows.
#
# Checkpoint strategy is role-differentiated:
#   queue DB → RESTART: Solid Queue workers run 24/7, so TRUNCATE cannot guarantee
#     a full checkpoint (active readers block it). RESTART waits for current readers
#     to finish their transactions before checkpointing, then resets the WAL write
#     position — more thorough than PASSIVE without permanently blocking new readers.
#   all other DBs → TRUNCATE: at 4am with near-zero traffic, no active readers.
#     TRUNCATE checkpoints all WAL pages and resets the WAL file to zero bytes,
#     fully freeing disk space and eliminating WAL scan overhead for the next day.
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

        checkpoint_mode = path.include?("_queue") ? "RESTART" : "TRUNCATE"
        db.execute("PRAGMA wal_checkpoint(#{checkpoint_mode});")

        # Log checkpoint result: [busy_pages, log_pages, checkpointed_pages]
        # busy_pages > 0 means active readers prevented a full checkpoint.
        result = db.execute("PRAGMA wal_checkpoint;")
        busy, log, checkpointed = result.first
        Rails.logger.info "[DatabaseMaintenance] #{File.basename(path)} — " \
          "#{checkpoint_mode} checkpoint: #{checkpointed}/#{log} pages, busy=#{busy}"
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
