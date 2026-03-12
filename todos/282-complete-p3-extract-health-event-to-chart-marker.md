---
status: complete
priority: p3
issue_id: "282"
tags: [code-review, rails, refactoring, models, charts]
dependencies: ["276"]
---

# Extract `HealthEvent#to_chart_marker` model method

## Problem Statement

Chart marker building logic for `HealthEvent` objects is duplicated across at least two locations (`DashboardController` and `PeakFlowReadingsController`) with a subtle inconsistency: the dashboard version guards `end_date` with `!e.point_in_time?` while the peak flow version does not (todo 276). The logic belongs on the model.

A `HealthEvent#to_chart_marker` instance method would centralise this, eliminate the duplication, and make the `point_in_time?` guard impossible to forget.

## Findings

- **File:** `app/controllers/dashboard_controller.rb` — inline marker hash building
- **File:** `app/controllers/peak_flow_readings_controller.rb` — inline marker hash building (missing `point_in_time?` guard)
- **Agent:** code-simplicity-reviewer, pattern-recognition-specialist

## Proposed Solutions

### Option A — `HealthEvent#to_chart_marker` instance method (Recommended)

```ruby
# app/models/health_event.rb
def to_chart_marker
  marker = { date: started_at.to_date, label: event_type.humanize }
  marker[:end_date] = ended_at.to_date unless point_in_time?
  marker
end
```

Both controllers replace their inline hash with `event.to_chart_marker`.

**Pros:** Single source of truth. Inconsistency in todo 276 is resolved automatically.
**Effort:** Small
**Risk:** None

### Option B — Leave inline, fix inconsistency with a comment

Add the `point_in_time?` guard to the peak flow controller and add a comment linking both locations.

**Pros:** No model change.
**Cons:** Still two places to maintain.
**Effort:** Trivial
**Risk:** Low (drift can recur)

## Recommended Action

Option A. Pairs with resolving todo 276.

## Technical Details

- **Affected files:**
  - `app/models/health_event.rb`
  - `app/controllers/dashboard_controller.rb`
  - `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `HealthEvent#to_chart_marker` returns `{ date:, label: }` for point-in-time events
- [ ] Returns `{ date:, end_date:, label: }` for duration events
- [ ] Both controllers delegate to the model method
- [ ] Existing chart tests pass

## Work Log

- 2026-03-11: Identified by code-simplicity-reviewer and pattern-recognition-specialist during code review of dev branch
