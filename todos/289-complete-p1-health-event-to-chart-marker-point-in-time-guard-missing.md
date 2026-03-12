---
status: pending
priority: p1
issue_id: "289"
tags: [code-review, rails, model, bug, charts]
dependencies: []
---

# HealthEvent#to_chart_marker missing point_in_time? guard on end_date

## Problem Statement
The new `HealthEvent#to_chart_marker` model method was extracted from inline hash construction in `DashboardController` and `PeakFlowReadingsController`. The original `DashboardController` code correctly guarded the `end_date` key: `marker[:end_date] = e.ended_at.to_date.to_s if !e.point_in_time? && e.ended_at.present?`. The extracted method dropped the `!point_in_time?` portion, leaving only `if ended_at.present?`. This means `gp_appointment` and `medication_change` events with a non-nil `ended_at` will now render incorrect duration spans on both the dashboard and peak flow charts.

## Findings
**Flagged by:** architecture-strategist

**Location:** `app/models/health_event.rb` — `to_chart_marker` method

Current broken code:
```ruby
def to_chart_marker
  marker = {
    date:         recorded_at.to_date.to_s,
    type:         event_type,
    label:        chart_label,
    css_modifier: event_type_css_modifier
  }
  marker[:end_date] = ended_at.to_date.to_s if ended_at.present?  # MISSING: !point_in_time? &&
  marker
end
```

`POINT_IN_TIME_TYPES` in the model includes `:gp_appointment` and `:medication_change`. These event types conceptually have no duration, even if `ended_at` is populated.

No model tests exist for `to_chart_marker`.

## Proposed Solutions

### Option A — Restore the point_in_time? guard (Recommended)
```ruby
marker[:end_date] = ended_at.to_date.to_s if !point_in_time? && ended_at.present?
```
**Pros:** Restores the original intended behaviour. One-word fix.
**Cons:** None.
**Effort:** Small. **Risk:** None.

### Option B — Enforce at DB level
Add a validation preventing `ended_at` on point-in-time events.
**Pros:** Prevents the bad data at source.
**Cons:** Schema migration needed; over-engineered for this fix.
**Effort:** Large. **Risk:** Medium.

## Recommended Action

## Technical Details
- **File:** `app/models/health_event.rb` — `to_chart_marker` method
- **Related:** `POINT_IN_TIME_TYPES = [:gp_appointment, :medication_change].freeze`
- **Impact:** Chart duration spans rendered incorrectly for point-in-time events with ended_at

## Acceptance Criteria
- [ ] `to_chart_marker` includes `!point_in_time? &&` in the `end_date` guard
- [ ] Model tests added for `to_chart_marker` covering: point-in-time event with ended_at (no end_date key), duration event with ended_at (end_date key present), duration event without ended_at (no end_date key)
- [ ] `bin/rails test` passes

## Work Log
- 2026-03-12: Identified in code review — architecture-strategist flagged guard was dropped during extraction

## Resources
- Branch: dev
- File: app/models/health_event.rb
- Related todo: 276-complete-p3-extract-health-event-to-chart-marker.md
