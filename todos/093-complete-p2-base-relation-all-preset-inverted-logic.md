---
status: pending
priority: p2
issue_id: "093"
tags: [code-review, rails, architecture, peak-flow, performance]
dependencies: []
---

# `index` action: `base_relation` reassignment for "all" preset is inside-out and fragile

## Problem Statement

The `index` action builds `base_relation` with a date filter, then unconditionally overwrites it for the "all" preset on the next line. The first assignment's result is discarded for the "all" case. While ActiveRecord laziness means no phantom query fires today, this pattern is confusing and fragile — any future developer adding something between the two assignments would silently create a bug for the "all" path.

Additionally, `Time.at(0)` (Unix epoch, 1970-01-01) is used as the implicit lower bound when no start date is specified, which is an undocumented sentinel assumption.

## Findings

**Flagged by:** kieran-rails-reviewer, performance-oracle, architecture-strategist, pattern-recognition-specialist

**Location:** `app/controllers/peak_flow_readings_controller.rb:46-55`

```ruby
base_relation = Current.user.peak_flow_readings
  .chronological
  .where(recorded_at: (@start_date&.beginning_of_day || Time.at(0))..(...))

# When preset is "all", remove the date filter
base_relation = Current.user.peak_flow_readings.chronological if @active_preset == "all"
#              ^^^^^ discards everything above for "all"
```

Reference: `SymptomLog` uses a model-layer `in_date_range` scope that handles nil naturally — no reassignment needed.

## Proposed Solutions

### Option A: Invert the logic — build base first, then narrow (Recommended)

```ruby
base_relation = Current.user.peak_flow_readings.chronological

unless @active_preset == "all"
  start_bound = @start_date&.beginning_of_day || Time.at(0)
  end_bound   = @end_date&.end_of_day || Time.current.end_of_day
  base_relation = base_relation.where(recorded_at: start_bound..end_bound)
end
```

- **Pros:** Clear intent; single base relation; safe to extend; `Time.at(0)` sentinel visible and commentable
- **Effort:** Small
- **Risk:** None (same SQL result)

### Option B: Add `in_date_range` scope to `PeakFlowReading` (Full fix)

Mirror `SymptomLog.scope :in_date_range` which accepts nil start/end as open-ended:

```ruby
# peak_flow_reading.rb
scope :in_date_range, ->(start_date, end_date) {
  relation = all
  relation = relation.where("recorded_at >= ?", start_date.beginning_of_day) if start_date
  relation = relation.where("recorded_at <= ?", end_date.end_of_day) if end_date
  relation
}
```

Controller becomes:
```ruby
base_relation = Current.user.peak_flow_readings.chronological
                             .in_date_range(@start_date, @end_date)
```

- **Pros:** Full parity with SymptomLog pattern; "all" handled naturally via nil dates; reusable in other contexts
- **Effort:** Medium
- **Risk:** None

## Recommended Action

Option B (full fix) if refactoring the model layer is acceptable. Option A as a targeted controller fix if model changes are out of scope.

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`, optionally `app/models/peak_flow_reading.rb`

## Acceptance Criteria

- [ ] "all" preset returns all user readings without a date WHERE clause
- [ ] 30-day default returns only readings within 30 days
- [ ] Custom date range filters correctly
- [ ] No `Time.at(0)` magic number without a constant or comment
- [ ] All 170 existing tests pass

## Work Log

- 2026-03-07: Identified during Phase 7 code review
