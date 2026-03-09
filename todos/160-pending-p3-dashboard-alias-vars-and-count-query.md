---
status: pending
priority: p3
issue_id: "160"
tags: [code-review, rails, simplicity, dashboard, health-events]
dependencies: []
---

# Dashboard: Remove Alias Vars and Derive Event Count from Loaded Data

## Problem Statement

Two small simplifications in `DashboardController` and `HealthEventsController`:

1. `chart_start`/`chart_end` in `DashboardController` are single-use alias variables that add noise with no clarity benefit.
2. `@header_event_count = events.size` in `HealthEventsController#index` may trigger an extra SQL `COUNT` if the relation loads lazily (depends on `loaded?` state at call time). Deriving from the already-loaded grouped hash is explicit and unambiguous.

## Findings

**Flagged by:** code-simplicity-reviewer (P1/P2 simplicity, net P3 impact)

### Issue 1 — `chart_start`/`chart_end` alias variables

**Location:** `app/controllers/dashboard_controller.rb`

```ruby
# Current — two alias vars used exactly once:
chart_start = week_start
chart_end   = Date.current

@health_event_markers = user.health_events
  .where(recorded_at: chart_start.beginning_of_day..chart_end.end_of_day)
```

**Fix:**
```ruby
@health_event_markers = user.health_events
  .where(recorded_at: week_start.beginning_of_day..Date.current.end_of_day)
```

### Issue 2 — `events.size` after group_by

**Location:** `app/controllers/health_events_controller.rb`

```ruby
# Current:
events = Current.user.health_events.includes(:rich_text_notes).recent_first
@grouped_events = events.group_by { |e| e.recorded_at.beginning_of_month }
@header_event_count = events.size
```

**Fix (derives from already-loaded data):**
```ruby
events = Current.user.health_events.includes(:rich_text_notes).recent_first
@grouped_events = events.group_by { |e| e.recorded_at.beginning_of_month }
@header_event_count = @grouped_events.values.sum(&:length)
```

## Acceptance Criteria

- [ ] `chart_start` and `chart_end` local variables removed from `DashboardController#index`
- [ ] `@header_event_count` derived from `@grouped_events` not from `events.size`
- [ ] `bin/rails test` passes

## Work Log

- 2026-03-09: Identified by code-simplicity-reviewer during `ce:review`.
