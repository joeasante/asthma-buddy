---
status: pending
priority: p3
issue_id: "012"
tags: [code-review, rails, sqlite, performance, simplicity]
dependencies: ["004"]
---

# WAL Initializer Is Redundant — `database.yml` Already Sets WAL Mode

## Problem Statement

`config/initializers/database_wal.rb` issues `PRAGMA journal_mode=WAL` on every connection checkout. `config/database.yml` already sets `properties: { journal_mode: wal }` which the `sqlite3` gem (>= 2.1, as Gemfile requires) correctly passes to the SQLite3 connection open call. The initializer is redundant work on every connection for all four databases.

Note: This is P3 (not P1) because the initializer is harmless and there is a legitimate use case (parallel test workers). Address after the SQLite PRAGMA tuning in todo #004 is done.

## Findings

**Flagged by:** code-simplicity-reviewer, kieran-rails-reviewer, performance-oracle

**Evidence of redundancy:** The gem's `properties` key is the Rails 8 / sqlite3 2.x native mechanism. WAL is a per-file setting that persists after first connection — the PRAGMA is a no-op on every subsequent connection to the same file.

**Legitimate use case:** Minitest parallel workers (`parallelize(workers: :number_of_processors)`) open multiple connections. The initializer ensures WAL is set even for connections opened by workers that may not go through the standard `properties` path. This is a real edge case that justifies keeping it — but it should be named and documented clearly.

## Proposed Solutions

### Option A — Remove the initializer entirely (Cleanest)
Trust `database.yml` `properties: { journal_mode: wal }`. If a parallel test runner issue is discovered, add the initializer back with a specific comment.

**Effort:** Trivial
**Risk:** Low (test with parallel test workers)

### Option B — Keep initializer but add WAL validation (Recommended if keeping)
If the initializer stays, validate that WAL actually set:

```ruby
module AsthmaBuddy
  module SQLiteWALMode
    def configure_connection
      super
      # Belt-and-suspenders: database.yml properties sets WAL at open time.
      # This ensures WAL for Minitest parallel worker connections.
      result = execute("PRAGMA journal_mode=WAL;")
      actual = result.first&.first
      Rails.logger.warn "[DB] WAL mode failed to activate (got: #{actual})" unless actual == "wal"
      # Additional performance PRAGMAs
      execute("PRAGMA busy_timeout=5000;")
      execute("PRAGMA synchronous=NORMAL;")
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(AsthmaBuddy::SQLiteWALMode)
end
```

**Effort:** Small
**Risk:** None

## Recommended Action

Option B — if keeping the initializer (for parallel test worker safety), name the module and add WAL validation. Reconsider Option A after verifying parallel test behavior.

## Technical Details

**Affected files:**
- `config/initializers/database_wal.rb`

**Acceptance Criteria:**
- [ ] Either initializer is removed and parallel tests pass, OR
- [ ] Initializer uses a named module with WAL validation

## Work Log

- 2026-03-06: Identified by code-simplicity-reviewer, rails-reviewer, performance-oracle. Deferred to P3 — not a runtime defect.
