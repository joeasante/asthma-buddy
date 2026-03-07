---
status: pending
priority: p3
issue_id: "105"
tags: [code-review, performance, rails, database, peak-flow]
dependencies: []
---

# Redundant single-column `user_id` index on `peak_flow_readings` — composite index covers it

## Problem Statement

`peak_flow_readings` has both `index_peak_flow_readings_on_user_id` (single-column) and `index_peak_flow_readings_on_user_id_and_recorded_at` (composite). The composite index covers all queries that filter on `user_id` alone (leftmost prefix rule), making the single-column index entirely redundant. It consumes storage and imposes a small write overhead on every INSERT/UPDATE with no query benefit.

## Findings

**Flagged by:** performance-oracle (P3)

**Location:** `db/schema.rb`

```ruby
t.index ["user_id", "recorded_at"], name: "index_peak_flow_readings_on_user_id_and_recorded_at"
t.index ["user_id"], name: "index_peak_flow_readings_on_user_id"  # ← redundant
```

## Proposed Solutions

### Option A: Remove the redundant index via migration (Recommended)

```ruby
class RemoveRedundantUserIdIndexFromPeakFlowReadings < ActiveRecord::Migration[8.1]
  def change
    remove_index :peak_flow_readings, name: "index_peak_flow_readings_on_user_id"
  end
end
```

- **Effort:** Tiny (migration only)
- **Risk:** None — composite index fully covers the use case

## Recommended Action

Option A.

## Technical Details

- **Affected files:** New migration, `db/schema.rb`
- **Database changes:** Remove `index_peak_flow_readings_on_user_id`

## Acceptance Criteria

- [ ] Migration removes the redundant index
- [ ] `db/schema.rb` no longer lists `index_peak_flow_readings_on_user_id`
- [ ] Composite `(user_id, recorded_at)` index remains
- [ ] All queries on `user_id` still use the composite index (verify with EXPLAIN)

## Work Log

- 2026-03-07: Identified during Phase 7 code review
