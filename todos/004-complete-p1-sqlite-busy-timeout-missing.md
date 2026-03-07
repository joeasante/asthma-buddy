---
status: pending
priority: p1
issue_id: "004"
tags: [code-review, performance, sqlite, database]
dependencies: []
---

# SQLite `busy_timeout` PRAGMA Missing — Concurrent Writers Get Immediate Error

## Problem Statement

`config/database.yml` sets `timeout: 5000` but this is the ActiveRecord **connection pool** wait time, not SQLite's internal busy timeout. Without `PRAGMA busy_timeout`, when two concurrent writers (e.g., a web request and a Solid Queue job) attempt to write simultaneously, SQLite returns `SQLITE_BUSY` immediately rather than retrying. This produces `ActiveRecord::StatementInvalid: SQLite3::BusyException: database is locked` errors under any concurrent write load — even on a personal app where Solid Queue jobs run inside Puma.

## Findings

**Flagged by:** performance-oracle (Priority 1 — do before features land)

**Location:** `config/database.yml` and `config/initializers/database_wal.rb`

The `timeout: 5000` YAML key controls how long ActiveRecord waits to check out a connection from the pool. It does not affect SQLite's internal retry behavior when a write lock is contested.

SQLite WAL mode reduces but does not eliminate write contention. With `SOLID_QUEUE_IN_PUMA: true`, Solid Queue worker threads share Puma's process and will write to the queue database concurrently with web request threads.

## Proposed Solutions

### Option A — Add to WAL initializer (Recommended)
Add `PRAGMA busy_timeout=5000;` to `configure_connection` in `config/initializers/database_wal.rb`:

```ruby
def configure_connection
  super
  execute("PRAGMA journal_mode=WAL;")
  execute("PRAGMA busy_timeout=5000;")    # wait 5s on lock contention
  execute("PRAGMA synchronous=NORMAL;")   # safe with WAL, 2-3x faster writes
end
```

**Pros:** Fixes the locking issue and adds `synchronous=NORMAL` for write performance in one pass.
**Cons:** Keeps the initializer (vs. removing it as recommended in todo #005).
**Effort:** Small
**Risk:** None

### Option B — Add to `database.yml` via `properties` key
```yaml
properties:
  journal_mode: wal
  busy_timeout: 5000
  synchronous: normal
```

**Pros:** Declarative; no initializer needed; aligns with the `properties`-first approach.
**Cons:** Requires verifying that the `sqlite3` gem >= 2.1 correctly forwards `busy_timeout` as a PRAGMA via the `properties` key (vs. as a connection string option).
**Effort:** Small
**Risk:** Low (verify gem behavior first)

### Option C — Use `retry_on` in ApplicationJob
Configure jobs to retry on `ActiveRecord::StatementInvalid`.

**Pros:** Application-level resilience.
**Cons:** Does not fix the root cause; web requests will still get errors.
**Effort:** Small
**Risk:** Does not address the core problem

## Recommended Action

Option A in the short term (add to initializer immediately). Evaluate Option B when consolidating SQLite PRAGMA configuration.

## Technical Details

**Affected files:**
- `config/initializers/database_wal.rb`

**Also consider adding:**
- `PRAGMA synchronous=NORMAL;` — safe with WAL, 2–3x faster on writes
- `PRAGMA cache_size=-32000;` — 32MB page cache
- `PRAGMA mmap_size=134217728;` — 128MB memory-mapped I/O

**Acceptance Criteria:**
- [ ] `PRAGMA busy_timeout=5000` set on every SQLite connection
- [ ] `PRAGMA synchronous=NORMAL` set on every SQLite connection
- [ ] Concurrent write test (or manual verification) shows no immediate `SQLITE_BUSY` errors under Solid Queue + Puma thread load

## Work Log

- 2026-03-06: Identified by performance-oracle in Foundation Phase review.
