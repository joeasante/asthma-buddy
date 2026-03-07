---
status: complete
priority: p3
issue_id: "046"
tags: [code-review, performance, sqlite, database]
dependencies: []
---

# WAL Mode Verification Runs on Every Connection — Convert to One-Time Boot Check

## Problem Statement

`AsthmaBuddy::SQLiteConnectionConfig#configure_connection` executes `PRAGMA journal_mode;` on every single connection open across all environments. Since WAL mode is set by `database.yml` via `properties: { journal_mode: wal }`, this check will virtually never fail in practice — it's a permanent debug assertion that adds overhead per connection and produces no actionable value once WAL is confirmed active.

## Findings

**Flagged by:** kieran-rails-reviewer (P3), performance-oracle (Priority 4), code-simplicity-reviewer

**Location:** `config/initializers/database_wal.rb`, lines 13-18

```ruby
result = execute("PRAGMA journal_mode;")
actual_mode = result.first&.first
unless actual_mode == "wal"
  Rails.logger.warn "[AsthmaBuddy] SQLite WAL mode is NOT active (got: #{actual_mode.inspect}) on #{@config[:database]}"
end
```

**Issues:**
1. Runs on every new connection (not per request, but includes reconnects, pool checkout for new threads, test DB setup)
2. In test, the check fires on every test that opens a connection — adds a `PRAGMA journal_mode;` round-trip to every test setup
3. If WAL is set by `database.yml`, this warning will never fire — making it dead code with overhead
4. If WAL is NOT set (misconfiguration), the warning in logs is the only signal — no exception is raised, so the bug silently persists

## Proposed Solutions

### Solution A: One-time boot check (Recommended)
Move the WAL verification outside `configure_connection` to a one-time `Rails.application.config.after_initialize` block:

```ruby
# In config/initializers/database_wal.rb, after the prepend:
Rails.application.config.after_initialize do
  next unless Rails.env.production?  # only check in production
  begin
    result = ActiveRecord::Base.connection.execute("PRAGMA journal_mode;")
    mode = result.first&.first
    unless mode == "wal"
      Rails.logger.error "[AsthmaBuddy] CRITICAL: SQLite WAL mode NOT active (got: #{mode.inspect})"
    end
  rescue => e
    Rails.logger.error "[AsthmaBuddy] Could not verify WAL mode: #{e.message}"
  end
end
```
- **Pros:** Runs exactly once at boot in production. Zero overhead in test. Raises an error-level log if misconfigured (not a warning).
- **Effort:** Small
- **Risk:** Low

### Solution B: Remove entirely
Since WAL is set by `database.yml`, a misconfigured DB would be obvious from `SQLITE_BUSY` errors under any load. The verification provides marginal value.
- **Effort:** Tiny (delete 6 lines)
- **Risk:** Slightly less observable configuration, acceptable for this app

## Recommended Action

Solution A for production safety. Solution B if simplicity is preferred.

## Technical Details

- **File:** `config/initializers/database_wal.rb`, lines 13-18
- **Note:** The other PRAGMAs (`busy_timeout`, `synchronous`, `cache_size`, `mmap_size`, `temp_store`) correctly belong in `configure_connection` — they must be set per connection. Only the verification check should move.

## Acceptance Criteria

- [ ] `PRAGMA journal_mode;` no longer executes on every connection open
- [ ] WAL mode is still verified at least once at boot (in production)
- [ ] Test suite does not execute any WAL verification queries
- [ ] Other PRAGMAs remain in `configure_connection` unchanged

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by kieran-rails-reviewer (P3), performance-oracle.
