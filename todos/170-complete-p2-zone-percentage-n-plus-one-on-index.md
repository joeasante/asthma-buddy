---
status: pending
priority: p2
issue_id: "170"
tags: [code-review, performance, n-plus-one, peak-flow]
dependencies: []
---

# zone_percentage Triggers One DB Query Per Reading Card on Index Page

## Problem Statement
`_reading_card.html.erb` calls `reading.zone_percentage`, which calls `zone_pct`, which calls `personal_best_at_reading_time` — a DB query against `personal_best_records` with `WHERE recorded_at <= reading_recorded_at ORDER BY recorded_at DESC LIMIT 1`. This fires once per card that has a zone. With 25 readings per page and most having zones, this is up to 25 extra queries per index page load, plus 25 more on every Turbo Frame filter navigation. Total: up to ~33 queries per page load (header queries + 25 N+1 + chart query + stats query).

## Findings
- `reading.zone_percentage` → `zone_pct` → `personal_best_at_reading_time` (1 DB query per call)
- Called from `_reading_card.html.erb`, which is rendered once per reading in the index list
- 25 readings per page = up to 25 extra queries per load
- Turbo Frame filter navigation re-runs the full index action, so every filter chip click also triggers all 25 queries
- The `zone` column is already snapshotted at save time; `zone_percentage` is not, creating an inconsistency

## Proposed Solutions

### Option A (Recommended)
Persist `zone_snapshot_pct` as an integer column on `peak_flow_readings`, populated in the same `before_save` callback that sets `zone`. `zone_percentage` reads from this column instead of recalculating. Consistent with the existing architectural decision to snapshot `zone` at save time.
- Pros: Eliminates all N+1 queries for zone percentage; zero queries on index load for this data; consistent with snapshotted `zone` design; correct at the time of recording (PB changes don't retroactively alter displayed percentages)
- Cons: Requires a migration and model update; backfill needed for existing records
- Effort: Medium
- Risk: Low

### Option B
Memoize `personal_best_at_reading_time` with `@personal_best_at_reading_time ||=`. Limits repeated calls on the same model instance to 1 query, but does not eliminate the N queries across a collection of 25 different instances.
- Pros: Simple one-line change; reduces redundant calls within a single instance lifecycle
- Cons: Does not fix the N+1 across a collection — still up to 25 queries per page load
- Effort: Small
- Risk: Low

### Option C
Precompute a personal-best-at-date hash in the controller and pass it to the view, eager-loading the relevant PB records for all readings in the current page in a single query.
- Pros: Reduces N queries to 1 controller query; no schema change needed
- Cons: Couples controller to view computation detail; more fragile than Option A; does not fix the inconsistency between snapshotted `zone` and live-computed `zone_percentage`
- Effort: Medium
- Risk: Medium

## Recommended Action

## Technical Details
- Affected files:
  - `app/models/peak_flow_reading.rb`
  - `db/migrate/...` (Option A: new migration for `zone_snapshot_pct` integer column)

## Acceptance Criteria
- [ ] `zone_percentage` on an index page load of 25 readings triggers at most 1 DB query (not 25)
- [ ] Existing zone percentage values are preserved or backfilled correctly
- [ ] No visual change to reading cards or zone display
- [ ] If Option A: `zone_snapshot_pct` column exists, is set in `before_save`, and `zone_percentage` reads from it

## Work Log
- 2026-03-10: Created via code review
