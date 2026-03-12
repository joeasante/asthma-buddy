# frozen_string_literal: true

# SQLite performance and concurrency configuration applied on every connection.
#
# Primary WAL configuration is in config/database.yml via `properties: { journal_mode: wal }`,
# which sets WAL at connection-open time. This initializer verifies the mode and applies
# performance PRAGMAs not available via the `properties` key.
module AsthmaBuddy
  module SQLiteConnectionConfig
    def configure_connection
      super

      # Wait up to 5 seconds on write lock contention before raising SQLITE_BUSY.
      # Without this, concurrent writers (e.g., Solid Queue + web request) fail immediately.
      # Note: database.yml `timeout:` is the ActiveRecord pool wait — not the SQLite busy timeout.
      execute("PRAGMA busy_timeout=5000;")

      # NORMAL is 2-3x faster than FULL and safe against application and OS crashes with WAL.
      # Trade-off: a hard power failure between a WAL write and the next checkpoint could lose
      # up to one checkpoint interval (~< 1 second) of committed transactions. Acceptable for
      # a single-server cloud VM in a datacenter with redundant power.
      execute("PRAGMA synchronous=NORMAL;")

      # Enforce foreign key constraints at the database level. Rails declares all FK
      # relationships via add_foreign_key in schema.rb — enabling this pragma catches
      # orphan writes that bypass Rails callbacks (e.g. direct SQL, fixtures, migrations).
      # Must be set per-connection; SQLite does not persist this setting.
      execute("PRAGMA foreign_keys=ON;")

      # Allow SQLite to use up to 4 auxiliary OS threads for parallel B-tree traversal,
      # sorting, and index operations. Default is 0 (single-threaded). On a multi-core VM
      # this improves throughput for complex dashboard and chart queries.
      execute("PRAGMA threads=4;")

      # Size cache, mmap, autocheckpoint and journal_size_limit by database role.
      # Primary needs larger caches for health data range scans and chart queries.
      # Queue/cache/cable are high-churn, small-row workloads that benefit from a higher
      # autocheckpoint threshold (fewer checkpoint interruptions per write burst).
      # At WEB_CONCURRENCY > 1, uniform large caches across all 4 DBs × N workers exhausts
      # memory on a 1-2 GB host.
      db_path = @config[:database].to_s
      if db_path.match?(/_cache|_queue|_cable/)
        execute("PRAGMA cache_size=-4000;")       # 4 MB  — sufficient for append-heavy workloads
        execute("PRAGMA mmap_size=33554432;")     # 32 MB
        execute("PRAGMA wal_autocheckpoint=4000;") # 16 MB WAL before auto-checkpoint — reduces
                                                   # checkpoint frequency for write-heavy DBs
        execute("PRAGMA journal_size_limit=33554432;") # 32 MB WAL cap; truncated after checkpoint
      else
        execute("PRAGMA cache_size=-16000;")      # 16 MB — headroom for multi-worker scaling
        execute("PRAGMA mmap_size=134217728;")    # 128 MB
        execute("PRAGMA wal_autocheckpoint=2000;") # 8 MB WAL before auto-checkpoint — balances
                                                   # read performance with WAL file size
        execute("PRAGMA journal_size_limit=67108864;") # 64 MB WAL cap; truncated after checkpoint
      end

      # Keep temp tables and sort buffers in memory rather than temp files.
      execute("PRAGMA temp_store=MEMORY;")
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(AsthmaBuddy::SQLiteConnectionConfig)
end

# One-time boot check: verify WAL mode is active in production.
# The per-connection PRAGMAs above correctly belong in configure_connection;
# only this verification check is elevated to boot time.
Rails.application.config.after_initialize do
  next unless Rails.env.production?

  begin
    result = ActiveRecord::Base.connection.execute("PRAGMA journal_mode;")
    mode = result.first&.fetch("journal_mode", nil)
    unless mode == "wal"
      Rails.logger.error "[AsthmaBuddy] CRITICAL: SQLite WAL mode NOT active on primary DB (got: #{mode.inspect})"
    end
  rescue => e
    Rails.logger.error "[AsthmaBuddy] Could not verify WAL mode: #{e.message}"
  end
end
