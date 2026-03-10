---
status: complete
priority: p2
issue_id: "195"
tags: [code-review, performance, database, phase-15-1]
dependencies: []
---

# Missing Composite Index: `dose_logs(user_id, medication_id, recorded_at)`

## Problem Statement
Both the main dose_logs query in `RelieverUsageController#index` and the `setup_monthly_stats` query filter on `user_id`, `medication_id` (via IN list/subquery), and `recorded_at`. The existing indexes cover these columns individually but not in combination. As dose log volume grows over months, SQLite must perform an index scan + filter instead of a single covering index lookup.

## Findings
- **File:** `db/schema.rb` (dose_logs table indexes, lines ~61-70)
- Existing indexes: `(medication_id, recorded_at)`, `(medication_id)`, `(recorded_at)`, `(user_id)` — none covers all three
- Both queries in `RelieverUsageController` filter on all three columns
- Performance agent rated this P2

## Proposed Solutions

### Option A (Recommended): Add composite index via migration
```ruby
add_index :dose_logs, [:user_id, :medication_id, :recorded_at],
          name: "index_dose_logs_on_user_medication_recorded_at"
```
- Effort: Small (migration + deploy)
- Risk: None — additive, no data changes

## Recommended Action

## Technical Details
- Affected files: new migration, `db/schema.rb`
- Note: `peak_flow_readings` already has `index on (user_id, recorded_at)` as reference

## Acceptance Criteria
- [ ] Migration adds composite index
- [ ] `db/schema.rb` updated
- [ ] Migration runs cleanly on fresh database

## Work Log
- 2026-03-10: Identified by performance-oracle in Phase 15.1 review
