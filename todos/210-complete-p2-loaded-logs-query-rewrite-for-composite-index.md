---
status: complete
priority: p2
issue_id: "210"
tags: [code-review, performance, database, rails, reliever-usage]
dependencies: []
---

# `loaded_logs` and `setup_monthly_stats` Queries — Composite Index May Be Bypassed; Eliminate Extra COUNT

## Problem Statement

Two related query issues in `RelieverUsageController`:

**1. `loaded_logs` query may not use the composite index.**
`where(medication: @relievers)` passes an ActiveRecord relation/array. Rails translates this to `medication_id IN (1, 2, ...)`. SQLite's planner frequently falls back to the single-column `user_id` index and filters `medication_id`/`recorded_at` in a second pass — reading all of a user's lifetime dose logs before filtering. An explicit `user_id:` integer equality gives the planner an unambiguous leading-column equality that the composite index `(user_id, medication_id, recorded_at)` is designed for.

**2. `setup_monthly_stats` issues a redundant `COUNT(*)` query.**
The monthly count can be derived entirely from `loaded_logs` (already in memory) since 1 month < 8 weeks, so all month-to-date logs are always in the loaded set.

## Findings

**Flagged by:** performance-oracle (P1 for #1, P2 for #2)

**Locations:**
- `app/controllers/reliever_usage_controller.rb` lines 41–46 (`loaded_logs`)
- `app/controllers/reliever_usage_controller.rb` lines 68–80 (`setup_monthly_stats`)

**Current loaded_logs query:**
```ruby
loaded_logs = Current.user.dose_logs
  .where(medication: @relievers)
  .where(recorded_at: period_start.beginning_of_day..Date.current.end_of_day)
  .to_a
```

**Current monthly COUNT:**
```ruby
@monthly_uses = Current.user.dose_logs
  .where(medication: @relievers)
  .where(recorded_at: Date.current.beginning_of_month.beginning_of_day..)
  .count
```

## Proposed Solutions

### Option A — Rewrite both queries (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
# Explicit user_id equality — unambiguous for composite index
reliever_ids = @relievers.map(&:id)

loaded_logs = DoseLog
  .where(user_id: Current.user.id, medication_id: reliever_ids)
  .where(recorded_at: period_start.beginning_of_day..Date.current.end_of_day)
  .to_a

# Derive monthly count from already-loaded data (no extra DB round-trip)
month_start = Date.current.beginning_of_month.beginning_of_day
@monthly_uses = loaded_logs.count { |l| l.recorded_at >= month_start }
tier = monthly_control_tier(@monthly_uses)
@monthly_pill_class = tier[:css]
@monthly_pill_label = tier[:label]
```

Delete `setup_monthly_stats` method entirely.

**Also close the open-ended upper bound** in the monthly query (currently `beginning_of_month..` with no upper bound, which could include future-dated logs). The in-memory derivation naturally respects the `period_start..Date.current.end_of_day` window.

**Pros:** One fewer SQL query per page load. Composite index used unambiguously. Eliminates `setup_monthly_stats` method stub. Closes open-ended date range.
**Cons:** Very minor — changes how `turbo_frame_request?` optimisation interacts. The turbo frame early-return for `@monthly_uses = 0` can be kept as a minor optimization (skips the `month_start` count when result is discarded).

### Option B — Keep current, add EXPLAIN verification
**Effort:** Smaller | **Risk:** None

Run `.explain` in console to verify the composite index is being used. If it is, no change needed.

```ruby
DoseLog.where(user_id: 1, medication_id: [1, 2])
       .where(recorded_at: 8.weeks.ago..Time.current)
       .explain
```

## Recommended Action

Option A. The refactor is small, eliminates one SQL query per non-frame page load, and makes the composite index usage unambiguous. Combine with deleting `setup_monthly_stats`.

## Technical Details

- **Affected files:** `app/controllers/reliever_usage_controller.rb`
- **Existing index:** `index_dose_logs_on_user_medication_recorded_at ON (user_id, medication_id, recorded_at)` — added in Phase 15.1 as todo 195

## Acceptance Criteria

- [ ] `loaded_logs` query uses explicit `DoseLog.where(user_id:, medication_id:)` syntax
- [ ] `setup_monthly_stats` method is deleted
- [ ] `@monthly_uses` is derived from `loaded_logs` in-memory
- [ ] Monthly count remains correct (verified by running existing tests)
- [ ] All 367 tests still pass

## Work Log

- 2026-03-10: Identified by performance-oracle. Composite index exists but query construction may prevent optimal plan selection.
