---
status: pending
priority: p2
issue_id: "134"
tags: [code-review, performance, database, peak-flow]
dependencies: []
---

# `DATE()` Wrapping Prevents Index Use on `personal_best_at_reading_time`

## Problem Statement

`PeakFlowReading#personal_best_at_reading_time` wraps the column in `DATE()`, preventing SQLite from using the B-tree index on `personal_best_records.recorded_at`. Every call to this method (triggered on save and display) does a full table scan on `personal_best_records`. As the table grows, zone calculation will slow proportionally.

Flagged by: performance-oracle (high severity).

## Findings

**File:** `app/models/peak_flow_reading.rb`, `personal_best_at_reading_time` method

```ruby
user.personal_best_records
    .where("DATE(recorded_at) <= DATE(?)", recorded_at)
    .order(recorded_at: :desc)
    .pick(:value)
```

`DATE(recorded_at)` applies a function to every row in the index, which forces a full scan. SQLite cannot use the index when a function wraps the indexed column.

The backfill migration (`20260308130000`) has the same pattern on line 11.

## Proposed Solution

Use a range comparison instead of `DATE()`:

```ruby
user.personal_best_records
    .where(recorded_at: ..recorded_at.end_of_day)
    .order(recorded_at: :desc)
    .pick(:value)
```

`recorded_at.end_of_day` returns `2026-03-08 23:59:59.999999999 UTC` — any record from that day or earlier is included, which is semantically equivalent to `DATE(recorded_at) <= DATE(?)` but uses the index.

Also update the backfill migration `20260308130000_backfill_nil_zone_peak_flow_readings.rb` line 11 from:
```ruby
.where("DATE(recorded_at) <= DATE(?)", reading.recorded_at)
```
to:
```ruby
.where(recorded_at: ..reading.recorded_at.end_of_day)
```

## Acceptance Criteria

- [ ] `personal_best_at_reading_time` no longer uses `DATE()` function wrapping
- [ ] Semantically equivalent: same personal best is returned for recordings on any time during the same day
- [ ] All existing zone calculation tests pass
- [ ] Backfill migration updated with same pattern

## Work Log

- 2026-03-08: Identified by performance-oracle as high severity
