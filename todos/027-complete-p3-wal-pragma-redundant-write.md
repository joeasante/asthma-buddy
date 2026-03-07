---
status: pending
priority: p3
issue_id: "027"
tags: [code-review, performance, sqlite, quality]
dependencies: []
---

# WAL Initializer Issues a Write PRAGMA on Every Connection — Should Be Read-Only Verification

## Problem Statement

`database_wal.rb` calls `execute("PRAGMA journal_mode=WAL;")` on every new connection, but WAL mode is already set by `database.yml`'s `properties: { journal_mode: wal }`. This double-set is a no-op (WAL persists at the file level) but adds an unnecessary write-side PRAGMA round-trip on every connection checkout. The real value is the verification logging — that can be preserved with a read-only check.

## Findings

**Flagged by:** performance-oracle (P2 finding)

**Location:** `config/initializers/database_wal.rb` lines 17-21

```ruby
# Current — issues a write PRAGMA unnecessarily
result = execute("PRAGMA journal_mode=WAL;")
actual_mode = result.first&.first
unless actual_mode == "wal"
  Rails.logger.warn "[AsthmaBuddy] SQLite WAL mode failed to activate (got: #{actual_mode.inspect})"
end
```

`database.yml` already sets WAL via `properties: { journal_mode: wal }` at connection-open time (before `configure_connection` runs). By the time the initializer runs, WAL is already set. The redundant write PRAGMA still works but is unnecessary overhead on every connection checkout.

The comment in the file acknowledges this ("belt-and-suspenders") but the value is the logging, not the setting.

## Proposed Solutions

### Solution A: Replace with read-only PRAGMA check (Recommended)

```ruby
# Verify WAL mode was set by database.yml properties — log if something went wrong.
# PRAGMA journal_mode returns [["wal"]] when active.
result = execute("PRAGMA journal_mode;")
actual_mode = result.first&.first
unless actual_mode == "wal"
  Rails.logger.warn "[AsthmaBuddy] SQLite WAL mode is NOT active (got: #{actual_mode.inspect}) " \
                    "on #{@config[:database]}"
end
```
- **Pros:** Preserves observability. Eliminates the redundant write. Includes db path in warning for easier debugging.
- **Effort:** Tiny (2 words changed: `=WAL;` → `;`, read vs write)
- **Risk:** None

## Recommended Action

Solution A. The change is 2 words. The observability is preserved. The warning now also includes the database path which makes log debugging easier.

## Technical Details

- **Affected file:** `config/initializers/database_wal.rb`
- **Lines:** 17-21

## Acceptance Criteria

- [ ] Line calls `PRAGMA journal_mode;` (no `=WAL`)
- [ ] Warning message includes `@config[:database]` or equivalent db path
- [ ] Comment explains `PRAGMA journal_mode` return value format
- [ ] `rails test` passes with WAL still active

## Work Log

- 2026-03-06: Identified by performance-oracle during /ce:review of foundation phase changes
