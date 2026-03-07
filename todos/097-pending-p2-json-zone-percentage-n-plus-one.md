---
status: pending
priority: p2
issue_id: "097"
tags: [code-review, performance, rails, peak-flow, n-plus-one, api]
dependencies: []
---

# N+1: `zone_percentage` in JSON response calls `personal_best_at_reading_time` per reading

## Problem Statement

`peak_flow_reading_json` includes `zone_percentage: reading.zone_percentage`. Tracing the call chain: `zone_percentage` → `zone_pct` → `personal_best_at_reading_time` → a `SELECT value FROM personal_best_records WHERE user_id = ? AND recorded_at <= ? ORDER BY recorded_at DESC LIMIT 1` query per reading. For a page of 25 readings, this is 25 additional database queries — a textbook N+1. The HTML path does not trigger this (zone is persisted), but any JSON API caller hits it.

## Findings

**Flagged by:** performance-oracle (P2), security-sentinel (P3, `created_at` also noted)

**Location:** `app/controllers/peak_flow_readings_controller.rb:126-135`

```ruby
def peak_flow_reading_json(reading)
  {
    id: reading.id,
    value: reading.value,
    recorded_at: reading.recorded_at,
    zone: reading.zone,
    zone_percentage: reading.zone_percentage,  # ← N+1
    created_at: reading.created_at             # ← unnecessary PHI metadata
  }
end
```

The covering index `(user_id, recorded_at, value)` on `personal_best_records` makes each individual query fast (index-only scan), but 25 round trips add up and grow linearly with page size.

## Proposed Solutions

### Option A: Persist `zone_percentage` at save time (Recommended — consistent with existing `zone` pattern)

`zone` is already persisted via a `before_save` callback. Add `zone_percentage` as a persisted column using the same pattern:

```ruby
# migration
add_column :peak_flow_readings, :zone_percentage, :integer

# model before_save
self.zone_percentage = compute_zone_percentage
```

`zone_percentage` in JSON then reads from a stored column — zero extra queries.

- **Pros:** Consistent with existing pattern; eliminates N+1 permanently; no preloading complexity
- **Effort:** Medium (migration + model callback)
- **Risk:** Low; existing `compute_zone` already has the logic

### Option B: Preload personal bests for the date range, compute in memory

Before serialising, fetch all personal best records for the relevant date range and use a Ruby lookup hash.

- **Pros:** No schema change
- **Cons:** More complex in-memory lookup; still requires a bounded date range query
- **Effort:** Medium

### Option C: Remove `zone_percentage` from JSON response (Minimal)

If no API consumer currently needs it, omit it. `zone` alone is sufficient for colour-coding.

- **Effort:** Tiny
- **Risk:** Breaking change if any client reads it

## Recommended Action

Option A — persist `zone_percentage` via `before_save`. Also remove `created_at` from the serialiser (PHI metadata with no documented consumer need).

## Technical Details

- **Affected files:** `app/models/peak_flow_reading.rb`, `app/controllers/peak_flow_readings_controller.rb`, new migration
- **Database changes:** `add_column :peak_flow_readings, :zone_percentage, :integer`

## Acceptance Criteria

- [ ] `GET /peak-flow-readings.json` with 25 results produces ≤ 3 total queries (not 25+ for zone_percentage)
- [ ] `created_at` removed from JSON serialiser
- [ ] `zone_percentage` in JSON matches what would have been computed dynamically
- [ ] Existing tests pass; add a test asserting zone_percentage is correct in JSON response

## Work Log

- 2026-03-07: Identified during Phase 7 code review
