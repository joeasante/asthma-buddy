# frozen_string_literal: true

# Enable WAL (Write-Ahead Logging) mode for SQLite across all environments.
# WAL mode allows concurrent reads and writes without blocking — essential for
# multi-user access on SQLite.
#
# Primary configuration is via config/database.yml `properties: { journal_mode: wal }`.
# This initializer acts as a belt-and-suspenders guarantee that WAL mode is set
# on every connection, even for adapters or gem versions that may not honour the
# properties key.
ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(
    Module.new do
      def configure_connection
        super
        execute("PRAGMA journal_mode=WAL;")
      end
    end
  )
end
