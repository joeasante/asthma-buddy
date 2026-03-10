---
status: pending
priority: p2
issue_id: "208"
tags: [code-review, performance, rails, reliever-usage]
dependencies: []
---

# `build_correlation` Uses O(n×m) Inner Loop — Pre-group Peak Flow Readings by Date

## Problem Statement

`build_correlation` scans the full `pf_readings` array linearly for every week in both `high_use_weeks` and `low_use_weeks`. With 12 weeks and 2 readings/day over 84 days, this is ~12 × 168 = ~2,016 iterations plus `recorded_at.to_date` object allocation on each one. The `build_weekly_data` method in the same controller already uses the correct pattern (`group_by` to build a date-keyed hash before the loop), making `build_correlation` inconsistent and unnecessarily wasteful.

## Findings

**Flagged by:** kieran-rails-reviewer (P1), performance-oracle (P2), code-simplicity-reviewer (P2)

**Location:** `app/controllers/reliever_usage_controller.rb` lines 121–141

```ruby
high_values = high_use_weeks.flat_map { |w|
  pf_readings.select { |r| r.recorded_at.to_date.between?(w[:week_start], w[:week_end]) }.map(&:value)
}
low_values = low_use_weeks.flat_map { |w|
  pf_readings.select { |r| r.recorded_at.to_date.between?(w[:week_start], w[:week_end]) }.map(&:value)
}
```

`pf_readings` is scanned once per high-use week and once per low-use week. `.to_date` allocates a new `Date` object on every iteration of the inner loop.

## Proposed Solutions

### Option A — Pre-group by date (mirrors `build_weekly_data` pattern) (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
def build_correlation(weekly_data, pf_readings)
  return nil if pf_readings.size < 2

  pf_by_date = pf_readings.group_by { |r| r.recorded_at.to_date }

  high_use_weeks = weekly_data.select { |w| w[:uses] >= GINA_REVIEW_THRESHOLD }
  low_use_weeks  = weekly_data.select { |w| w[:uses] <  GINA_REVIEW_THRESHOLD }

  return nil if high_use_weeks.empty? || low_use_weeks.empty?

  values_for = ->(weeks) {
    weeks.flat_map { |w|
      (w[:week_start]..w[:week_end]).flat_map { |d| pf_by_date.fetch(d, []).map(&:value) }
    }
  }

  high_values = values_for.(high_use_weeks)
  low_values  = values_for.(low_use_weeks)

  return nil if high_values.empty? || low_values.empty?

  high_avg = high_values.sum.to_f / high_values.size
  low_avg  = low_values.sum.to_f  / low_values.size

  { high_avg: high_avg.round, low_avg: low_avg.round }
end
```

**Pros:** O(readings) grouping pass once, then O(7) hash lookups per week. Consistent with `build_weekly_data`. Eliminates repeated `.to_date` allocations.
**Cons:** None significant.

### Option B — Keep current implementation
**Effort:** None | **Risk:** Low (data volumes are small)

At realistic scale (12 weeks, 2 readings/day) this is ~2,000 iterations. Not a user-perceptible problem today.

**Pros:** No change needed.
**Cons:** Inconsistent pattern. Will matter more if window is ever extended.

## Recommended Action

Option A. The fix is 5 lines and makes `build_correlation` consistent with `build_weekly_data`. Eliminate the inconsistency while the controller is still being actively modified.

## Technical Details

- **Affected files:** `app/controllers/reliever_usage_controller.rb`
- **No test changes required** (behaviour is identical; all 367 tests should still pass)

## Acceptance Criteria

- [ ] `build_correlation` pre-groups `pf_readings` by date before iterating weeks
- [ ] No `recorded_at.to_date` calls inside the per-week loop
- [ ] All 367 tests still pass
- [ ] Output of `build_correlation` is identical to current implementation for all inputs

## Work Log

- 2026-03-10: Identified by code review. Performance-oracle, kieran-rails, and simplicity-reviewer all flagged the inconsistency with `build_weekly_data`.
