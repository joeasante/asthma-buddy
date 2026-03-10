---
status: pending
priority: p3
issue_id: "159"
tags: [code-review, performance, database, health-events]
dependencies: []
---

# Add Index on `[user_id, ended_at]` for Future `ongoing?` Queries

## Problem Statement

`health_events` has a composite index on `[user_id, recorded_at]` but no index on `ended_at`. The model defines `ongoing?` which indicates future SQL queries filtering `WHERE ended_at IS NULL` are expected. Adding the index now prevents a full-table-scan when that query is written.

## Findings

**Flagged by:** performance-oracle (P2)

**Location:** `db/migrate/20260309000002_add_ended_at_to_health_events.rb` — column added with no index

**Current index:** `add_index :health_events, [ :user_id, :recorded_at ]`

**Missing index:** `[user_id, ended_at]` for the expected future scope:
```ruby
user.health_events.where(ended_at: nil).where.not(event_type: POINT_IN_TIME_TYPES)
```

## Fix

Add a migration:
```ruby
add_index :health_events, [ :user_id, :ended_at ]
```

## Acceptance Criteria

- [ ] Migration adds `[user_id, ended_at]` index
- [ ] `db/schema.rb` reflects the new index
- [ ] `bin/rails db:migrate` runs without error

## Work Log

- 2026-03-09: Identified by performance-oracle during `ce:review`. Latent risk — no current queries use `ended_at` in WHERE clause, but `ongoing?` predicate signals this is coming.
